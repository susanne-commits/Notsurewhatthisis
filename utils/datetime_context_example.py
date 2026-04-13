"""
Examples showing how to use datetime_context.py with different LLM providers.
Run this file directly to see the output:  python utils/datetime_context_example.py
"""

from datetime_context import inject_datetime, wrap_messages_openai, wrap_messages_anthropic


# ── 1. Plain string injection (works with any LLM) ──────────────────────────
base_system = "You are a helpful assistant for Lumarinne Lifestyle."
system_with_date = inject_datetime(base_system)
print("=== Plain inject_datetime ===")
print(system_with_date)
print()


# ── 2. OpenAI / compatible APIs ─────────────────────────────────────────────
print("=== wrap_messages_openai (no existing system msg) ===")
messages = [{"role": "user", "content": "What day is it today?"}]
messages = wrap_messages_openai(messages, system_prompt="You are a helpful assistant.")
for m in messages:
    print(f"[{m['role']}] {m['content']}")
print()

print("=== wrap_messages_openai (existing system msg) ===")
messages = [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "What year is it?"},
]
messages = wrap_messages_openai(messages)
for m in messages:
    print(f"[{m['role']}] {m['content']}")
print()


# ── 3. Anthropic Claude ──────────────────────────────────────────────────────
print("=== wrap_messages_anthropic ===")
system = wrap_messages_anthropic("You are a helpful assistant for Lumarinne Lifestyle.")
print(system)
print()

# Then use like:
#
#   import anthropic
#   client = anthropic.Anthropic()
#   response = client.messages.create(
#       model="claude-sonnet-4-6",
#       system=system,
#       messages=[{"role": "user", "content": "What day is it?"}],
#       max_tokens=256,
#   )


# ── 4. Custom timezone example ───────────────────────────────────────────────
from datetime import timezone, timedelta

print("=== Custom timezone (US Eastern = UTC-4 in summer) ===")
eastern = timezone(timedelta(hours=-4), name="ET")
print(inject_datetime("You are a helpful assistant.", tz=eastern))
