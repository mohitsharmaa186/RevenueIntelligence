# OpenAI Named Credential — Manual Setup (Developer Edition)

External Credential metadata is not included in this package because it fails
deployment in fresh Developer Edition orgs. Configure authentication after deploy.

## Steps

1. Deploy the project (Named Credential deploys with `protocol: NoAuthentication`).
2. Go to **Setup → Named Credentials**.
3. Open **OpenAI API** → **Edit**.
4. Set **URL** to `https://api.openai.com` (if not already set).
5. Under **Custom Headers**, add:
   - **Header Name:** `Authorization`
   - **Header Value:** `Bearer YOUR_OPENAI_API_KEY`
6. Save.

Alternatively create via Setup UI only:

1. **Setup → Named Credentials → New Legacy**
2. **Label:** OpenAI API
3. **Name:** OpenAI_API (must match `callout:OpenAI_API` in Apex)
4. **URL:** `https://api.openai.com`
5. Add custom header `Authorization: Bearer sk-...`
6. Save.

## Verify

Run **Analyze Deal** on an Opportunity record. If the key is missing, the app
uses the built-in rule-based fallback in `AIDealAnalysisService` (no error).

## Apex callout reference

```
callout:OpenAI_API/v1/chat/completions
```

Defined in `AIDealAnalysisService.cls` — do not change the Named Credential
API name without updating that class.
