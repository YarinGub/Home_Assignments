import streamlit as st
import re
from difflib import SequenceMatcher

# --- Core Logic Functions ---

def get_similarity(a, b):
    return SequenceMatcher(None, a, b).ratio()

def extract_base_domain(domain):
    parts = domain.split('.')
    return ".".join(parts[-2:]) if len(parts) >= 2 else domain

def get_all_domains(text):
    # Extracts domains from plain text and URLs
    found = re.findall(r'\b(?:[a-z0-9-]+\.)+[a-z]{2,}\b', text.lower())
    urls = re.findall(r'https?://([a-z0-9.-]+)', text.lower())
    return list(set(found + urls))

def analyze_content(content_lower):
    trusted_brands = ["paypal", "google", "microsoft", "facebook", "apple", "amazon"]
    indicators = []
    
    # 1. Check for Hard Urgent Language (Critical)
    urgent_words = ["urgent", "immediately", "action required", "suspended", "verify", "account locked", "final notice", "confirm"]
    for word in urgent_words:
        if word in content_lower:
            indicators.append(f"CRITICAL: Urgent language detected ('{word}')")

    # 2. Check for Soft Indicators (Informational - Safe)
    soft_words = ["security alert", "new sign-in", "check activity", "sign-in"]
    for word in soft_words:
        if word in content_lower:
            indicators.append(f"INFO: Standard security phrase found ('{word}')")

    # 3. Check for IP Addresses (Critical)
    ips = re.findall(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b', content_lower)
    for ip in ips:
        indicators.append(f"CRITICAL: Suspicious IP address detected ({ip})")

    # 4. Domain & Spoofing Analysis (Critical)
    domains = get_all_domains(content_lower)
    for domain in domains:
        base = extract_base_domain(domain)
        brand_part = base.split('.')[0]

        for brand in trusted_brands:
            similarity = get_similarity(brand_part, brand)
            
            # Detect Typosquatting (e.g., paypa1 vs paypal)
            if 0.8 <= similarity < 1.0:
                indicators.append(f"CRITICAL: Spoofed domain detected ('{domain}' mimics '{brand}')")
            
            # Detect Brand Misuse (e.g., secure-paypal.net)
            elif brand in brand_part and base != f"{brand}.com":
                # Ensure it's not a legitimate subdomain like accounts.google.com
                if not base.endswith(f"{brand}.com"):
                    indicators.append(f"CRITICAL: Brand misuse detected in domain '{domain}'")

    return list(set(indicators))

# --- Streamlit UI Design ---

st.set_page_config(page_title="Smart Phishing Detector", page_icon="🛡️")

st.title("🛡️ Smart Email Phishing Detector")
st.write("Upload an email text file to evaluate its risk level.")

# File Uploader
uploaded_file = st.file_uploader("Select an email file (txt)", type="txt")

if uploaded_file is not None:
    # Read the file content
    content = uploaded_file.getvalue().decode("utf-8")
    
    st.subheader("Email Content Preview:")
    st.text_area("", value=content, height=150, disabled=True)
    
    if st.button("Run Security Scan"):
        # Run analysis
        all_indicators = analyze_content(content.lower())
        
        # Filter into Critical and Info
        critical_hits = [i for i in all_indicators if "CRITICAL" in i]
        info_hits = [i for i in all_indicators if "INFO" in i]
        
        st.divider()
        
        # Display Result
        if critical_hits:
            st.error("🔴 RESULT: LIKELY A PHISHING ATTEMPT")
            st.subheader("Critical Security Risks:")
            for hit in sorted(critical_hits):
                st.write(f"❌ {hit.replace('CRITICAL: ', '')}")
        else:
            st.success("✅ RESULT: EMAIL LOOKS SAFE")
            st.write("No critical phishing indicators were found.")

        # Show informational notes if they exist
        if info_hits:
            with st.expander("View Informational Notes"):
                for info in sorted(info_hits):
                    st.write(f"ℹ️ {info.replace('INFO: ', '')}")