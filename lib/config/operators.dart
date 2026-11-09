/// Operator accounts (keep in sync with `firestore.rules` `isAdmin()`).
const operatorEmails = {'yuto.mabe@gmail.com'};

bool isOperatorEmail(String? email) {
  if (email == null) return false;
  return operatorEmails.contains(email.trim().toLowerCase());
}
