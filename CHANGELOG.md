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
