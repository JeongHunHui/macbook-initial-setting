#!/usr/bin/env python3
"""Claude/Codex usage for tmux."""
import fcntl
import json, os, select, sys, time, subprocess
from datetime import datetime, timezone
from pathlib import Path

HOME = Path.home()
CACHE = HOME / ".tmux/.claude-usage-cache.json"
CODEX_CACHE = HOME / ".tmux/.codex-usage-cache.json"
CODEX_SESSION_DIR = HOME / ".codex/sessions"
OMC_CACHE = HOME / ".claude/plugins/oh-my-claudecode/.usage-cache.json"
CACHE_TTL = 300      # fresh cache: 5 min
CODEX_CACHE_TTL = 60 # live account snapshot cache
FAIL_TTL = 300       # don't retry API for 5 min after failure
STALE_TTL = 1800     # show stale data up to 30 min

def read_cache(path=CACHE):
    try: return json.loads(path.read_text())
    except: return None

def write_cache(out, error=False, path=CACHE, data_ts=None):
    now = int(time.time())
    try: path.write_text(json.dumps({"ts": now, "data_ts": now if data_ts is None else data_ts, "out": out, "err": error}))
    except: pass

def get_token():
    try:
        r = subprocess.run(
            ["/usr/bin/security", "find-generic-password", "-s", "Claude Code-credentials", "-w"],
            capture_output=True, text=True, timeout=3
        )
        if r.returncode != 0: return None
        d = json.loads(r.stdout.strip())
        c = d.get("claudeAiOauth", d)
        exp = c.get("expiresAt")
        if exp and isinstance(exp, (int, float)) and exp < time.time() * 1000:
            return None
        return c.get("accessToken")
    except: return None

def fetch_usage(token):
    try:
        r = subprocess.run(
            ["curl", "-s", "--max-time", "5",
             "-H", f"Authorization: Bearer {token}",
             "-H", "anthropic-beta: oauth-2025-04-20",
             "https://api.anthropic.com/api/oauth/usage"],
            capture_output=True, text=True, timeout=10
        )
        d = json.loads(r.stdout)
        if "error" in d: return None
        return d
    except: return None

def fmt_remaining(iso):
    if not iso: return ""
    try:
        if isinstance(iso, (int, float)) or str(iso).isdigit():
            dt = datetime.fromtimestamp(int(iso), timezone.utc)
        else:
            dt = datetime.fromisoformat(str(iso).replace("Z", "+00:00"))
        s = max(0, int((dt - datetime.now(timezone.utc)).total_seconds()))
        d, s = divmod(s, 86400); h, s = divmod(s, 3600); m = s // 60
        if d > 0: return f"{d}d{h}h"
        if h > 0: return f"{h}h{m}m"
        return f"{m}m"
    except: return ""

def color(p):
    if p >= 80: return "#[fg=#f38ba8]"
    if p >= 50: return "#[fg=#f9e2af]"
    return "#[fg=#a6e3a1]"

def format_output(resp):
    f5 = max(0, int(resp.get("five_hour", {}).get("utilization", 0) or 0))
    wk = max(0, int(resp.get("seven_day", {}).get("utilization", 0) or 0))
    r5 = fmt_remaining(resp.get("five_hour", {}).get("resets_at", ""))
    rw = fmt_remaining(resp.get("seven_day", {}).get("resets_at", ""))
    p5 = f"({r5})" if r5 else ""
    pw = f"({rw})" if rw else ""
    return f"#[fg=#8a8a8a]claude {color(f5)}5h:{f5}%{p5} {color(wk)}wk:{wk}%{pw}#[fg=#8a8a8a]", f5, wk

def ensure_claude_label(out):
    if "claude " in out or "codex " in out:
        return out
    return f"#[fg=#8a8a8a]claude {out}"

def is_codex_pane():
    try:
        target = ["-t", sys.argv[1]] if len(sys.argv) > 1 and sys.argv[1].startswith('%') else []
        r = subprocess.run(
            ["tmux", "display-message", *target, "-p", "#{pane_current_command} #{pane_pid}"],
            capture_output=True, text=True, timeout=1
        )
        if r.returncode != 0:
            return False
        pane_info = r.stdout.strip().split()
        command = pane_info[0].lower() if pane_info else ""
        if command == "codex":
            return True
        pane_pid = int(pane_info[1]) if len(pane_info) > 1 and pane_info[1].isdigit() else 0
        if not pane_pid:
            return False

        ps = subprocess.run(
            ["ps", "ax", "-o", "pid=,ppid=,command="],
            capture_output=True, text=True, timeout=1
        )
        if ps.returncode != 0:
            return False

        command_by_pid = {}
        child_list_by_pid = {}
        for line in ps.stdout.splitlines():
            part_list = line.strip().split(None, 2)
            if len(part_list) < 3 or not part_list[0].isdigit() or not part_list[1].isdigit():
                continue
            pid = int(part_list[0])
            ppid = int(part_list[1])
            command_by_pid[pid] = part_list[2].lower()
            child_list_by_pid.setdefault(ppid, []).append(pid)

        stack = [pane_pid]
        while stack:
            pid = stack.pop()
            proc_command = command_by_pid.get(pid, "")
            if "claude " in proc_command or proc_command.endswith("/claude"):
                return False
            if "codex" in proc_command and "mcp-server" not in proc_command:
                return True
            stack.extend(child_list_by_pid.get(pid, []))
        return False
    except:
        return False

def format_codex_rate_limits(rate_limits):
    window_list = [
        rate_limits.get("primary", {}) or {},
        rate_limits.get("secondary", {}) or {},
    ]

    def find_window(target_minutes):
        return next(
            (window for window in window_list
             if int(window.get("window_minutes", window.get("windowDurationMins", 0)) or 0)
             == target_minutes),
            None,
        )

    def format_window(label, window):
        if not window:
            return f"#[fg=#585858]{label}:-"
        percent = window.get("used_percent", window.get("usedPercent"))
        if percent is None:
            return f"#[fg=#585858]{label}:?"
        used = max(0, int(percent))
        remaining = fmt_remaining(window.get("resets_at", window.get("resetsAt", "")))
        reset = f"({remaining})" if remaining else ""
        return f"{color(used)}{label}:{used}%{reset}"

    five_hour = find_window(300)
    weekly = find_window(10080)
    return (
        "#[fg=#8a8a8a]codex "
        f"{format_window('5h', five_hour)} {format_window('wk', weekly)}"
        "#[fg=#8a8a8a]"
    )

def fetch_codex_rate_limits():
    """Ask Codex's app-server for the current account snapshot."""
    proc = None
    try:
        proc = subprocess.Popen(
            ["codex", "app-server", "--stdio"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            bufsize=0,
        )
        request_list = [
            {"jsonrpc": "2.0", "id": 0, "method": "initialize", "params": {
                "clientInfo": {"name": "tmux-usage", "title": "tmux usage", "version": "1.0.0"},
                "capabilities": {"experimentalApi": True},
            }},
            {"jsonrpc": "2.0", "method": "initialized"},
            {"jsonrpc": "2.0", "id": 1, "method": "account/rateLimits/read", "params": {
                "excludeResetCreditDetails": True,
            }},
        ]
        def send(request):
            proc.stdin.write((json.dumps(request) + "\n").encode())
        send(request_list[0])
        buffer = b''
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            ready, _, _ = select.select([proc.stdout], [], [], max(0, deadline - time.monotonic()))
            if not ready:
                break
            chunk = os.read(proc.stdout.fileno(), 65536)
            if not chunk:
                break
            buffer += chunk
            while b'\n' in buffer:
                line, buffer = buffer.split(b'\n', 1)
                response = json.loads(line)
                if response.get('id') == 0:
                    if 'error' in response:
                        return None
                    for request in request_list[1:]:
                        send(request)
                elif response.get("id") == 1:
                    return response.get("result", {}).get("rateLimits")
    except:
        return None
    finally:
        if proc:
            proc.terminate()
            try: proc.wait(timeout=1)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
            for stream in (proc.stdin, proc.stdout):
                if stream:
                    stream.close()
    return None

def find_codex_rate_limits():
    try:
        session_file_list = sorted(
            CODEX_SESSION_DIR.glob("**/*.jsonl"),
            key=lambda p: p.stat().st_mtime,
            reverse=True,
        )
    except:
        return None

    for session_file in session_file_list[:20]:
        try:
            if time.time() - session_file.stat().st_mtime > STALE_TTL:
                continue
            # Session logs can be hundreds of MB; only scan a bounded tail.
            with session_file.open('rb') as stream:
                size = stream.seek(0, 2)
                stream.seek(max(0, size - 524288))
                line_list = stream.read().decode(errors='ignore').splitlines()
        except:
            continue
        for line in reversed(line_list):
            if '"token_count"' not in line or '"rate_limits"' not in line:
                continue
            try:
                event = json.loads(line)
            except:
                continue
            rate_limits = event.get("rate_limits") or event.get("payload", {}).get("rate_limits")
            timestamp = event.get('timestamp')
            try:
                age = time.time() - datetime.fromisoformat(timestamp.replace('Z', '+00:00')).timestamp()
            except (ValueError, TypeError, AttributeError):
                continue
            if rate_limits and 0 <= age < STALE_TTL:
                return {**rate_limits, '_observed_at': time.time() - age}
    return None

def print_codex_usage():
    cache = read_cache(CODEX_CACHE)
    now = time.time()
    if cache and now - cache.get("ts", 0) < CODEX_CACHE_TTL:
        print(cache["out"], end="")
        return

    # Multiple tmux clients should not start duplicate app servers.
    CODEX_CACHE.parent.mkdir(parents=True, exist_ok=True)
    with CODEX_CACHE.with_suffix('.lock').open('a') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print(cache.get('out', '') if cache and now - cache.get('ts', 0) < STALE_TTL
                  else '#[fg=#585858]codex 5h:? wk:?', end='')
            return
        # Recheck after acquiring the lock: another process may have just refreshed.
        cache = read_cache(CODEX_CACHE)
        if cache and now - cache.get('ts', 0) < CODEX_CACHE_TTL:
            print(cache['out'], end='')
            return
        rate_limits = fetch_codex_rate_limits()
        if rate_limits:
            out = format_codex_rate_limits(rate_limits)
            write_cache(out, path=CODEX_CACHE)
            print(out, end='')
            return
        # Keep a recent successful snapshot instead of regressing to older logs.
        data_ts = cache.get('data_ts', cache.get('ts', 0)) if cache else 0
        if cache and now - data_ts < STALE_TTL and 'wk:?' not in cache['out']:
            out = cache['out'].removesuffix(' (stale)') + ' (stale)'
            write_cache(out, error=True, path=CODEX_CACHE, data_ts=data_ts)
            print(out, end='')
            return
        rate_limits = find_codex_rate_limits()
        out = format_codex_rate_limits(rate_limits) + ' (log)' if rate_limits else '#[fg=#585858]codex 5h:? wk:?'
        write_cache(out, error=True, path=CODEX_CACHE,
                    data_ts=rate_limits.get('_observed_at') if rate_limits else None)
        print(out, end='')
        return

def write_omc_cache(resp, f5, wk):
    try:
        OMC_CACHE.parent.mkdir(parents=True, exist_ok=True)
        d = {
            "timestamp": int(time.time() * 1000),
            "data": {
                "fiveHourPercent": f5, "weeklyPercent": wk,
                "fiveHourResetsAt": resp.get("five_hour", {}).get("resets_at", ""),
                "weeklyResetsAt": resp.get("seven_day", {}).get("resets_at", ""),
            },
            "error": False, "source": "anthropic"
        }
        for key, field in [("seven_day_sonnet", "sonnet"), ("seven_day_opus", "opus")]:
            if key in resp:
                d["data"][f"{field}WeeklyPercent"] = max(0, int(resp[key].get("utilization", 0) or 0))
                d["data"][f"{field}WeeklyResetsAt"] = resp[key].get("resets_at", "")
        OMC_CACHE.write_text(json.dumps(d, indent=2))
    except: pass

def main():
    if is_codex_pane():
        print_codex_usage()
        return

    cache = read_cache()
    now = time.time()

    if cache:
        age = now - cache.get("ts", 0)
        is_err = cache.get("err", False)
        cache["out"] = ensure_claude_label(cache.get("out", ""))
        # Fresh success cache or recent failure -> use it
        if (not is_err and age < CACHE_TTL) or (is_err and age < FAIL_TTL):
            print(cache["out"], end=""); return
        # Stale but usable
        if age < STALE_TTL and not is_err:
            # Try refresh in background, but show stale for now
            stale_out = cache["out"]
        else:
            stale_out = None
    else:
        stale_out = None

    token = get_token()
    if not token:
        out = stale_out or "#[fg=#585858]claude 5h:- wk:-"
        print(out, end=""); return

    resp = fetch_usage(token)
    if not resp:
        # API failed - cache the failure to avoid hammering
        if stale_out:
            write_cache(stale_out, error=True)
            print(stale_out, end="")
        else:
            fallback = "#[fg=#585858]claude 5h:? wk:?"
            write_cache(fallback, error=True)
            print(fallback, end="")
        return

    out, f5, wk = format_output(resp)
    write_omc_cache(resp, f5, wk)
    write_cache(out)
    print(out, end="")

if __name__ == '__main__':
    main()
