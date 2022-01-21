terraform {
  required_providers {
    cloudflare = {
      source = "cloudflare/cloudflare"
      version = "~> 3.0"
    }
  }
}

locals {
  cloudflare_api_token = ""
  site_domain = "gotta-cache-em-all.com"
  vercel_cname = "cname.vercel-dns.com"
}

provider "cloudflare" {
  api_token = local.cloudflare_api_token
}

data "cloudflare_zones" "domain" {
  filter {
    name = local.site_domain
  }
}

# <DNS Config>
resource "cloudflare_record" "vercel_a" {
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = local.site_domain
  value   = "76.76.21.21"
  type    = "A"
  ttl     = 1
  proxied = true
}

resource "cloudflare_record" "vercel_cname" {
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = "www"
  value   = local.vercel_cname
  type    = "CNAME"
  ttl     = 1
  proxied = true
}

resource "cloudflare_record" "vercel_txt" {
  zone_id = data.cloudflare_zones.domain.zones[0].id
  name    = local.site_domain
  value   = local.vercel_cname
  type    = "TXT"
  ttl     = 1
  proxied = false
}
# </DNS Config>

# </Page rules>
resource "cloudflare_page_rule" "well-known" {
  zone_id = data.cloudflare_zones.domain.zones[0].id
  target = "*.${data.cloudflare_zones.domain.zones[0].name}/.well-known/*"
  priority = 2

  actions {
    ssl = "off"
  }
}

resource "cloudflare_page_rule" "gotta-cache-em-all_com" {
  zone_id = data.cloudflare_zones.domain.zones[0].id
  target = "*${data.cloudflare_zones.domain.zones[0].name}/*"
  priority = 1

  actions {
    cache_level    = "aggressive"
    edge_cache_ttl = 7200
  }
}
# </Page rules>
