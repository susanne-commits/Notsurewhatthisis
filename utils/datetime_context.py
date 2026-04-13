"""
datetime_context.py
-------------------
Injects the current date and time into LLM system prompts so the model always
knows the correct date. Works with any LLM API that accepts a system prompt
(Claude, OpenAI, Gemini, Mistral, etc.).

Usage
-----
    from utils.datetime_context import inject_datetime, wrap_messages_openai, wrap_messages_anthropic

    # --- OpenAI / compatible APIs ---
    messages = [{"role": "user", "content": "What day is it?"}]
    messages = wrap_messages_openai(messages)
    response = openai_client.chat.completions.create(model="gpt-4o", messages=messages)

    # --- Anthropic Claude ---
    system = "You are a helpful assistant."
    system = inject_datetime(system)
    response = anthropic_client.messages.create(
        model="claude-sonnet-4-6",
        system=system,
        messages=[{"role": "user", "content": "What day is it?"}],
        max_tokens=256,
    )

    # --- Plain string (any other LLM) ---
    system = inject_datetime("You are a helpful assistant.")
    # → "You are a helpful assistant.\n\n[Context: Today is Monday, April 13 2026. Current time is 14:35 UTC.]"
"""

from datetime import datetime, timezone


def get_datetime_snippet(tz: timezone = timezone.utc) -> str:
    """Return a short, human-readable date/time string for the given timezone."""
    now = datetime.now(tz)
    day_name = now.strftime("%A")          # e.g. Monday
    date_str = now.strftime("%B %d %Y")   # e.g. April 13 2026
    time_str = now.strftime("%H:%M")      # e.g. 14:35
    tz_name = now.strftime("%Z")          # e.g. UTC
    return f"Today is {day_name}, {date_str}. Current time is {time_str} {tz_name}."


def inject_datetime(system_prompt: str, tz: timezone = timezone.utc) -> str:
    """
    Append a date/time context block to any system prompt string.

    Parameters
    ----------
    system_prompt : str
        The existing system prompt text. Can be empty.
    tz : timezone
        Timezone to use. Defaults to UTC.

    Returns
    -------
    str
        The system prompt with a date/time line appended.
    """
    snippet = get_datetime_snippet(tz)
    separator = "\n\n" if system_prompt.strip() else ""
    return f"{system_prompt}{separator}[Context: {snippet}]"


def wrap_messages_openai(
    messages: list[dict],
    system_prompt: str = "",
    tz: timezone = timezone.utc,
) -> list[dict]:
    """
    Inject date/time into an OpenAI-style messages list.

    - If a system message already exists at index 0, the datetime is appended
      to it.
    - If no system message exists, one is prepended.

    Parameters
    ----------
    messages : list[dict]
        OpenAI-format message list, e.g. [{"role": "user", "content": "..."}]
    system_prompt : str
        Optional base system prompt to use when none is already present.
    tz : timezone
        Timezone to use. Defaults to UTC.

    Returns
    -------
    list[dict]
        Updated message list with datetime context in the system message.
    """
    messages = list(messages)  # don't mutate the caller's list
    if messages and messages[0]["role"] == "system":
        messages[0] = {
            "role": "system",
            "content": inject_datetime(messages[0]["content"], tz),
        }
    else:
        messages.insert(0, {"role": "system", "content": inject_datetime(system_prompt, tz)})
    return messages


def wrap_messages_anthropic(
    system_prompt: str,
    tz: timezone = timezone.utc,
) -> str:
    """
    Inject date/time into an Anthropic-style system prompt string.

    Parameters
    ----------
    system_prompt : str
        The system prompt passed to anthropic.messages.create(system=...).
    tz : timezone
        Timezone to use. Defaults to UTC.

    Returns
    -------
    str
        System prompt with datetime context appended.
    """
    return inject_datetime(system_prompt, tz)
