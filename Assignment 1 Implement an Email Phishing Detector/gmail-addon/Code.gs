
function onGmailMessageOpen(e) {
  if (!e || !e.gmail || !e.gmail.messageId) {
    return buildErrorCard_("Please open an email to start the scan.");
  }

  try {
    var accessToken = e.gmail.accessToken;
    GmailApp.setCurrentMessageAccessToken(accessToken);
    
    var message = GmailApp.getMessageById(e.gmail.messageId);
    var content = message.getPlainBody().toLowerCase();
    var sender = message.getFrom().toLowerCase();
    var subject = message.getSubject();

    var result = analyzePhishingFull_(content, sender);

    return buildResultCard_(subject, message.getFrom(), result);
  } catch (err) {
    return buildErrorCard_("Error accessing email: " + err.message);
  }
}

function analyzePhishingFull_(text, sender) {
  var indicators = [];
  var score = 0;
  
  // 1. Whitelist - החרגת שולחים רשמיים
  var legitDomains = ["google.com", "accounts.google.com", "paypal.com", "microsoft.com", "apple.com", "amazon.com"];
  for (var i = 0; i < legitDomains.length; i++) {
    if (sender.indexOf(legitDomains[i]) !== -1) {
      return { likely: false, score: 0, indicators: ["Verified Official Sender (Safe)"] };
    }
  }

  // 2. Urgent Language
  var urgentPhrases = ["urgent", "immediately", "action required", "suspended", "verify", "account locked", "confirm"];
  urgentPhrases.forEach(function(p) {
    if (text.indexOf(p) !== -1) {
      if (indicators.length < 2) indicators.push("Urgent language: " + p);
    }
  });
  if (indicators.length > 0) score += 1;

  // 3. Typosquatting (דמיון למותגים)
  var brands = ["paypal", "google", "microsoft", "apple", "amazon"];
  var words = text.split(/[\s@.]+/);
  for (var i = 0; i < words.length; i++) {
    for (var j = 0; j < brands.length; j++) {
      var sim = calculateSimilarity_(words[i], brands[j]);
      if (sim >= 0.8 && sim < 1.0) {
        indicators.push("Potential spoofing: '" + words[i] + "' mimics '" + brands[j] + "'");
        score += 1;
        break;
      }
    }
    if (score >= 2) break;
  }

  // 4. Technical Indicators
  if (text.match(/https?:\/\/(\d{1,3}\.){3}\d{1,3}/)) {
    indicators.push("Suspicious IP address in link");
    score += 1;
  }

  return { likely: score >= 2, score: score, indicators: indicators.length ? indicators : ["No suspicious patterns"] };
}


function calculateSimilarity_(s1, s2) {
  if (s1.length < 3 || s2.length < 3) return 0;
  var longer = s1.length > s2.length ? s1 : s2;
  var shorter = s1.length > s2.length ? s2 : s1;
  var costs = [];
  for (var i = 0; i <= longer.length; i++) {
    var lastValue = i;
    for (var j = 0; j <= shorter.length; j++) {
      if (i == 0) costs[j] = j;
      else if (j > 0) {
        var newValue = costs[j - 1];
        if (longer.charAt(i - 1) != shorter.charAt(j - 1))
          newValue = Math.min(Math.min(newValue, lastValue), costs[j]) + 1;
        costs[j - 1] = lastValue;
        lastValue = newValue;
      }
    }
    if (i > 0) costs[shorter.length] = lastValue;
  }
  return (longer.length - costs[shorter.length]) / parseFloat(longer.length);
}


function buildResultCard_(subject, from, result) {
  var header = CardService.newCardHeader()
    .setTitle(result.likely ? "🚨 LIKELY PHISHING" : "✅ SAFE")
    .setSubtitle("Risk Score: " + result.score + "/3");

  var section = CardService.newCardSection()
    .addWidget(CardService.newKeyValue().setTopLabel("From").setContent(from))
    .addWidget(CardService.newTextParagraph().setText("<b>Findings:</b><br>• " + result.indicators.join("<br>• ")));

  return CardService.newCardBuilder().setHeader(header).addSection(section).build();
}

function buildErrorCard_(message) {
  return CardService.newCardBuilder()
    .addSection(CardService.newCardSection().addWidget(CardService.newTextParagraph().setText(message)))
    .build();
}