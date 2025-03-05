## {{ .info.Title | default ".env" }}

## Inherited Variables
PROJECT_ROOT={{ .Env.PROJECT_ROOT | default "A" }}
VENDOR_PROFILE={{ getenv "VENDOR_PROFILE" "commercial" }}
FAKE_VALUE={{ .Env.FAKE_VALUE | default "fake" }}

## Secrets


## {{ .info.Disclaimer | default "Generated from env.tpl" }}
