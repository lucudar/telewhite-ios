import Foundation

// Telewhite: "Resend Automatically".
//
// A message that fails to send stops there: it turns red and waits for the person to notice, open
// the menu and tap Retry. On a phone that is on the move — a tunnel, a lift, a handover between
// towers — that is a lot of noticing for something the app could simply do again.
//
// The rule for what may be repeated is narrow on purpose. Telegram knows a name for every failure
// it considers the user's business: slow mode, a ban, a file that is too large, a peer that will
// not accept the message. Repeating those changes nothing and buries an answer the person needs to
// see. What is left — a request that timed out, a connection that dropped mid-flight, a server that
// said nothing useful — is what this retries.

/// How many times a single message may send itself again before it gives up and turns red as usual.
let telewhiteAutoResendAttemptLimit: Int32 = 4

func telewhiteAutoResendEnabled() -> Bool {
    return UserDefaults.standard.bool(forKey: "telewhite.mods.autoResendFailed")
}

/// Errors Telegram has a user-facing reason for are never retried — `sendMessageReasonForError`
/// returning a value is exactly the signal that the failure is meaningful rather than transient.
/// Everything else is treated as the network having a bad moment.
func telewhiteShouldAutoResend(errorDescription: String) -> Bool {
    if !telewhiteAutoResendEnabled() {
        return false
    }
    if sendMessageReasonForError(errorDescription) != nil {
        return false
    }
    // A file reference that went stale has its own single-shot retry a few lines up in
    // PendingMessageManager, and it re-uploads rather than re-sends. Leave it to that path.
    if errorDescription.hasPrefix("FILEREF_INVALID") || errorDescription.hasPrefix("FILE_REFERENCE_") {
        return false
    }
    return true
}
