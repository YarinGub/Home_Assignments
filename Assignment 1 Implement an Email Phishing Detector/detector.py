import re
from difflib import SequenceMatcher

def get_similarity(a, b):
    """Calculates how similar two strings are."""
    return SequenceMatcher(None, a, b).ratio()

def extract_base_domain(domain):
    """Simplifies a domain to its core (e.g., accounts.google.com -> google.com)."""
    parts = domain.split('.')
    return ".".join(parts[-2:]) if len(parts) >= 2 else domain

def get_all_domains(text):
    """Extracts all potential domains from text and URLs."""
    # Find all domain-like strings
    found = re.findall(r'\b(?:[a-z0-9-]+\.)+[a-z]{2,}\b', text.lower())
    # Extract domains specifically from URLs
    urls = re.findall(r'https?://([a-z0-9.-]+)', text.lower())
    return list(set(found + urls))

def analyze_email(file_path):
    trusted_brands = ["paypal", "google", "microsoft", "facebook", "apple", "amazon"]
    
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            content = file.read()
            content_lower = content.lower()

        indicators = []

        # 1. Check for Hard Urgent Language
        urgent_words = ["urgent", "immediately", "action required", "suspended", "verify", "account locked"]
        for word in urgent_words:
            if word in content_lower:
                indicators.append(f"CRITICAL: Urgent language found ('{word}')")

        # 2. Check for Soft Indicators (Informational - won't trigger 'Phishing' status alone)
        soft_words = ["security alert", "new sign-in", "check activity"]
        for word in soft_words:
            if word in content_lower:
                indicators.append(f"INFO: Standard security phrase found ('{word}')")

        # 3. Check for IP Addresses
        ips = re.findall(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b', content)
        for ip in ips:
            indicators.append(f"CRITICAL: Suspicious IP address detected ({ip})")

        # 4. Domain & Spoofing Analysis
        domains = get_all_domains(content_lower)
        for domain in domains:
            base = extract_base_domain(domain)
            brand_part = base.split('.')[0]

            for brand in trusted_brands:
                similarity = get_similarity(brand_part, brand)
                
                # Detect Typosquatting (e.g., goog1e.com)
                if 0.8 <= similarity < 1.0:
                    indicators.append(f"CRITICAL: Spoofed domain detected ('{domain}' mimics '{brand}')")
                
                # Detect Brand Misuse (e.g., secure-google.net)
                elif brand in brand_part and base != f"{brand}.com":
                    indicators.append(f"CRITICAL: Brand misuse ('{domain}' is not an official {brand} domain)")

        # --- Output Report ---
        print("\n" + "="*50)
        print(f"REPORT FOR: {file_path}")
        print("="*50)

        # Filter indicators
        critical_hits = [i for i in indicators if "CRITICAL" in i]
        
        if critical_hits:
            print("RESULT: LIKELY A PHISHING ATTEMPT")
            print("\nDetected Threats:")
            for ind in sorted(list(set(indicators))):
                print(f" [!] {ind}")
        else:
            print("RESULT: EMAIL LOOKS SAFE")
            if indicators:
                print("\nObservations (Normal Security Content):")
                for ind in sorted(list(set(indicators))):
                    print(f" [-] {ind}")
            else:
                print("No suspicious patterns found.")
        print("="*50 + "\n")

    except FileNotFoundError:
        print(f"Error: {file_path} not found.")

if __name__ == "__main__":
    # Test on your files
    analyze_email("data/email_sample.txt") 
    analyze_email("data/email_sample 2.txt") 
    analyze_email("data/email_sample 3.txt") 
    analyze_email("data/email_sample 4.txt") 
    analyze_email("data/email_sample 5.txt") 