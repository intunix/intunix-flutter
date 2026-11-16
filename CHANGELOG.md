## 1.7.3

A banner or popup stays open when the user taps outside it; only a modal closes on an outside tap.

Wraps Intunix Android 1.7.3 and iOS 1.7.3.

## 1.7.2

The conversational form has one scroll area: in a modal, popup or on a short screen the chat log
takes the remaining height instead of scrolling inside a scrolling card.

Wraps Intunix Android 1.7.2 and iOS 1.7.2.

## 1.7.1

Chat fixes. Switching language in a conversational form now re-renders the welcome message,
the questions already asked (including the one on screen), the completion message and the
answers to choice questions in the new language; AI follow-up questions and free-text answers
stay as written, and a half-typed answer is kept. The language switcher sits closer to the
close button.
Wraps Intunix Android 1.7.1 and iOS 1.7.1.

## 1.7.0

Multi-language and conversational forms. A form in two or more languages shows an in-form
language switcher and is laid out right to left for Arabic, Persian, Hebrew and Urdu; responses
carry their `language`. `IntunixOptions(locale:)`, `Intunix.setLocale()` and
`IntunixForm(locale:)` set the app's language. Conversational and AI-enhanced forms work with no
code change; the assistant's name comes from the console (default "Nia"), and the form carries on
with its own questions if the AI is unreachable.
Wraps Intunix Android 1.7.0 and iOS 1.7.0.

## 1.6.0

Dark mode. Forms follow the app: inline `IntunixForm` reads your `Theme`'s brightness,
popups follow the phone/native setting. Per-form console lock and dark background.
`IntunixOptions(theme:)`, `Intunix.setTheme()` and `IntunixForm(theme:)` override it.
Wraps Intunix Android 1.6.1 and iOS 1.6.0.

## 1.5.6

First release. Wraps Intunix Android 1.5.6 and iOS 1.5.6: initialize, identify, reset, track,
screen, setContext, showForm, register/unregister, and the `IntunixForm` inline widget.
