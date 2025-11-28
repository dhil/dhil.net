function isKnownCrawler() {
    // Poor man's attempt at detecting known indexing services.
    const botPattern = "(googlebot\/|bot|Googlebot-Mobile|Googlebot-Image|Google favicon|Mediapartners-Google|bingbot|slurp|java|wget|curl|Commons-HttpClient|Python-urllib|libwww|httpunit|nutch|phpcrawl|msnbot|jyxobot|FAST-WebCrawler|FAST Enterprise Crawler|biglotron|teoma|convera|seekbot|gigablast|exabot|ngbot|ia_archiver|GingerCrawler|webmon |httrack|webcrawler|grub.org|UsineNouvelleCrawler|antibot|netresearchserver|speedy|fluffy|bibnum.bnf|findlink|msrbot|panscient|yacybot|AISearchBot|IOI|ips-agent|tagoobot|MJ12bot|dotbot|woriobot|yanga|buzzbot|mlbot|yandexbot|purebot|Linguee Bot|Voyager|CyberPatrol|voilabot|baiduspider|citeseerxbot|spbot|twengabot|postrank|turnitinbot|scribdbot|page2rss|sitebot|linkdex|Adidxbot|blekkobot|ezooms|dotbot|Mail.RU_Bot|discobot|heritrix|findthatfile|europarchive.org|NerdByNature.Bot|sistrix crawler|ahrefsbot|Aboundex|domaincrawler|wbsearchbot|summify|ccbot|edisterbot|seznambot|ec2linkfinder|gslfbot|aihitbot|intelium_bot|facebookexternalhit|yeti|RetrevoPageAnalyzer|lb-spider|sogou|lssbot|careerbot|wotbox|wocbot|ichiro|DuckDuckBot|lssrocketcrawler|drupact|webcompanycrawler|acoonbot|openindexspider|gnam gnam spider|web-archive-net.com.bot|backlinkcrawler|coccoc|integromedb|content crawler spider|toplistbot|seokicks-robot|it2media-domain-crawler|ip-web-crawler.com|siteexplorer.info|elisabot|proximic|changedetection|blexbot|arabot|WeSEE:Search|niki-bot|CrystalSemanticsBot|rogerbot|360Spider|psbot|InterfaxScanBot|Lipperhey SEO Service|CC Metadata Scaper|g00g1e.net|GrapeshotCrawler|urlappendbot|brainobot|fr-crawler|binlar|SimpleCrawler|Livelapbot|Twitterbot|cXensebot|smtbot|bnf.fr_bot|A6-Indexer|ADmantX|Facebot|Twitterbot|OrangeBot|memorybot|AdvBot|MegaIndex|SemanticScholarBot|ltx71|nerdybot|xovibot|BUbiNG|Qwantify|archive.org_bot|Applebot|TweetmemeBot|crawler4j|findxbot|SemrushBot|yoozBot|lipperhey|y!j-asr|Domain Re-Animator Bot|AddThis)";
    const re = new RegExp(botPattern, 'i');
    return re.test(navigator.userAgent);
}

function glue(prefix, suffix) {
    return [prefix.join(""), suffix.join("")].join("@");
}

function academic() {
    const prefix = ['d', 'a', 'n', 'i', 'e', 'l', '.', 'h', 'i', 'l', 'l', 'e', 'r', 's', 't', 'r', 'o', 'm'];
    const suffix = ['e', 'd', '.', 'a', 'c', '.', 'u', 'k'];
    return glue(prefix, suffix);
}

function corporate() {
    return academic() + "?subject=[Category Labs] Enquiry";
}

function makeHref(protocol, x, y) {
    return "<a href=\"" + protocol + ":" + x + "\">" + y + "</a>";
}

function showAddress(elem, addrFn, txt) {
    if (isKnownCrawler()) {
        elem.innerHTML = "[this information is hidden]";
    } else {
        const protocol = ['m', 'a', 'i', 'l', 't', 'o'];
        const addr = addrFn();
        elem.innerHTML = makeHref(protocol.join(""), addrFn(), txt === null ? addr : txt);
    }
}

function unveil(ac, co) {
    if (ac !== null) {
        showAddress(document.getElementById(ac), academic, null);
    }
    if (co !== null) {
        showAddress(document.getElementById(co), corporate, "[Category Labs]");
    }
}

document.addEventListener("DOMContentLoaded", function() { return unveil("reveal-ac", "reveal-co"); });
