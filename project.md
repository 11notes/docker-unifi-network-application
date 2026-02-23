${{ content_synopsis }} This image will provide you a rock solid<sup>1</sup> Unifi controller.

${{ content_uvp }} Good question! Because ...

${{ github:> [!IMPORTANT] }}
${{ github:> }}* ... this image runs [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) as 1000:1000
${{ github:> }}* ... this image is auto updated to the latest version via CI/CD
${{ github:> }}* ... this image has a health check
${{ github:> }}* ... this image runs read-only
${{ github:> }}* ... this image is very small
${{ github:> }}* ... this image is created via a secure and pinned CI/CD process

If you value security, simplicity and optimizations to the extreme, then this image might be for you.

${{ title_volumes }}
* **${{ json_root }}/var** - Directory of all configuration data and sites

${{ content_compose }}

${{ content_defaults }}

${{ content_environment }}

${{ content_source }}

${{ content_parent }}

${{ content_built }}

${{ content_tips }}

${{ title_caution }}
${{ github:> [!CAUTION] }}
${{ github:> }}* This image, because it’s read only, contains a default SSL certificate that is the same for all images. Do not expose this container directly anywhere, always put apps behind a reverse proxy! You can also replace the certificate keystore located in ``` /usr/lib/unifi/data/keystore``` with your own if you feel uncomfortable with the default certificate or do not want to use a reverse proxy

# DISCLAIMERS
* <sup>1</sup> This image will automatically disable anonymous telemetry collected by Ubiquiti by adding a flag (`config.system_cfg.1=system.analytics.anonymous=disabled`) to each sites `config.properties`. You will still have to disable telemetry in the global settings too, to disable *all* telemetry. You can check your telemetry status by SSH’ing into an access point and checking ` grep analytics /tmp/system.cfg`, the output should read `disabled`. Make sure to also DNS block the FQDN `trace.svc.ui.com` in your DNS blocker.