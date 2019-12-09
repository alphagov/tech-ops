(function() {
  "use strict";
  window.GOVUK = window.GOVUK || {};

  var GoogleAnalyticsUniversalTracker = function(id, cookieDomain) {
    configureProfile(id, cookieDomain);
    anonymizeIp();

    function configureProfile(id, cookieDomain) {
      sendToGa('create', id, {'cookieDomain': cookieDomain});
    }

    function anonymizeIp() {
      // https://developers.google.com/analytics/devguides/collection/analyticsjs/advanced#anonymizeip
      sendToGa('set', 'anonymizeIp', true);
    }
  };

  GoogleAnalyticsUniversalTracker.load = function() {
    (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
        (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
                             m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
    })(window,document,'script','//www.google-analytics.com/analytics.js','ga');
  };

  // https://developers.google.com/analytics/devguides/collection/analyticsjs/pages
  GoogleAnalyticsUniversalTracker.prototype.trackPageview = function(path, title, options) {
    var options = options || {};

    if (typeof path === "string") {
      var pageviewObject = {
            page: path
          };

      if (typeof title === "string") {
        pageviewObject.title = title;
      }

      // Set the transport method for the pageview
      // Typically used for enabling `navigator.sendBeacon` when the page might be unloading
      // https://developers.google.com/analytics/devguides/collection/analyticsjs/field-reference#transport
      if (options.transport) {
        pageviewObject.transport = options.transport;
      }

      sendToGa('send', 'pageview', pageviewObject);
    } else {
      sendToGa('send', 'pageview');
    }
  };

  // https://developers.google.com/analytics/devguides/collection/analyticsjs/events
  GoogleAnalyticsUniversalTracker.prototype.trackEvent = function(category, action, options) {
    var value,
        options = options || {},
        evt = {
          hitType: 'event',
          eventCategory: category,
          eventAction: action
        };

    // Label is optional
    if (typeof options.label === "string") {
      evt.eventLabel = options.label;
    }

    // Page is optional
    if (typeof options.page === "string") {
      evt.page = options.page;
    }

    // Value is optional, but when used must be an
    // integer, otherwise the event will be invalid
    // and not logged
    if (options.value || options.value === 0) {
      value = parseInt(options.value, 10);
      if (typeof value === "number" && !isNaN(value)) {
        evt.eventValue = value;
      }
    }

    // Prevents an event from affecting bounce rate
    // https://developers.google.com/analytics/devguides/collection/analyticsjs/events#implementation
    if (options.nonInteraction) {
      evt.nonInteraction = 1;
    }

    // Set the transport method for the event
    // Typically used for enabling `navigator.sendBeacon` when the page might be unloading
    // https://developers.google.com/analytics/devguides/collection/analyticsjs/field-reference#transport
    if (options.transport) {
      evt.transport = options.transport;
    }

    sendToGa('send', evt);
  };

  /*
    https://developers.google.com/analytics/devguides/collection/analyticsjs/social-interactions
    network – The network on which the action occurs (e.g. Facebook, Twitter)
    action – The type of action that happens (e.g. Like, Send, Tweet)
    target – Specifies the target of a social interaction.
             This value is typically a URL but can be any text.
  */
  GoogleAnalyticsUniversalTracker.prototype.trackSocial = function(network, action, target) {
    sendToGa('send', {
      'hitType': 'social',
      'socialNetwork': network,
      'socialAction': action,
      'socialTarget': target
    });
  };

  /*
   https://developers.google.com/analytics/devguides/collection/analyticsjs/cross-domain
   trackerId - the UA account code to track the domain against
   name      - name for the tracker
   domain    - the domain to track
  */
  GoogleAnalyticsUniversalTracker.prototype.addLinkedTrackerDomain = function(trackerId, name, domain) {
    sendToGa('create',
             trackerId,
             'auto',
             {'name': name});
    // Load the plugin.
    sendToGa('require', 'linker');
    sendToGa(name + '.require', 'linker');

    // Define which domains to autoLink.
    sendToGa('linker:autoLink', [domain]);
    sendToGa(name + '.linker:autoLink', [domain]);

    sendToGa(name + '.set', 'anonymizeIp', true);
    sendToGa(name + '.send', 'pageview');
  };

  // https://developers.google.com/analytics/devguides/collection/analyticsjs/custom-dims-mets
  GoogleAnalyticsUniversalTracker.prototype.setDimension = function(index, value) {
    sendToGa('set', 'dimension' + index, String(value));
  };

  function sendToGa() {
    if (typeof window.ga === "function") {
      ga.apply(window, arguments);
    }
  }

  GOVUK.GoogleAnalyticsUniversalTracker = GoogleAnalyticsUniversalTracker;
})();
;(function() {
  "use strict";
  window.GOVUK = window.GOVUK || {};

  // For usage and initialisation see:
  // https://github.com/alphagov/govuk_frontend_toolkit/blob/master/docs/analytics.md#create-an-analytics-tracker

  var Analytics = function(config) {
    this.trackers = [];
    if (typeof config.universalId != 'undefined') {
      this.trackers.push(new GOVUK.GoogleAnalyticsUniversalTracker(config.universalId, config.cookieDomain));
    }
  };

  Analytics.prototype.sendToTrackers = function(method, args) {
    for (var i = 0, l = this.trackers.length; i < l; i++) {
      var tracker = this.trackers[i],
          fn = tracker[method];

      if (typeof fn === "function") {
        fn.apply(tracker, args);
      }
    }
  };

  Analytics.load = function() {
    GOVUK.GoogleAnalyticsUniversalTracker.load();
  };

  Analytics.prototype.trackPageview = function(path, title, options) {
    this.sendToTrackers('trackPageview', arguments);
  };

  /*
    https://developers.google.com/analytics/devguides/collection/analyticsjs/events
    options.label – Useful for categorizing events (eg nav buttons)
    options.value – Values must be non-negative. Useful to pass counts
    options.nonInteraction – Prevent event from impacting bounce rate
  */
  Analytics.prototype.trackEvent = function(category, action, options) {
    this.sendToTrackers('trackEvent', arguments);
  };

  Analytics.prototype.trackShare = function(network) {
    this.sendToTrackers('trackSocial', [network, 'share', location.pathname]);
  };

  /*
    The custom dimension index must be configured within the
    Universal Analytics profile
   */
  Analytics.prototype.setDimension = function(index, value) {
    this.sendToTrackers('setDimension', arguments);
  };

  /*
   Add a beacon to track a page in another GA account on another domain.
   */
  Analytics.prototype.addLinkedTrackerDomain = function(trackerId, name, domain) {
    this.sendToTrackers('addLinkedTrackerDomain', arguments);
  };

  GOVUK.Analytics = Analytics;
})();
;(function() {
  "use strict";
  GOVUK.analyticsPlugins = GOVUK.analyticsPlugins || {};
  GOVUK.analyticsPlugins.downloadLinkTracker = function (options) {
    var options = options || {},
        downloadLinkSelector = options.selector;

    if (downloadLinkSelector) {
      $('body').on('click', downloadLinkSelector, trackDownload);
    }

    function trackDownload(evt) {
      var $link = getLinkFromEvent(evt),
          href = $link.attr('href'),
          evtOptions = {transport: 'beacon'},
          linkText = $.trim($link.text());

      if (linkText) {
        evtOptions.label = linkText;
      }

      GOVUK.analytics.trackEvent('Download Link Clicked', href, evtOptions);
    }

    function getLinkFromEvent(evt) {
      var $target = $(evt.target);

      if (!$target.is('a')) {
        $target = $target.parents('a');
      }

      return $target;
    }
  }
}());
;(function() {
  'use strict';

  // Load Google Analytics libraries
  GOVUK.Analytics.load();

  // Use document.domain in dev, preview and staging so that tracking works
  // Otherwise explicitly set the domain as www.gov.uk (and not gov.uk).
  var cookieDomain = (document.domain === 'www.gov.uk') ? '.www.gov.uk' : document.domain;

  // Configure profiles, setup custom vars, track initial pageview
  GOVUK.analytics = new GOVUK.Analytics({
    universalId: 'UA-26179049-1',
    cookieDomain: cookieDomain
  });

  // Set custom dimensions before tracking pageviews

  if (window.devicePixelRatio) {
    GOVUK.analytics.setDimension(11, window.devicePixelRatio);
  }

  // Track initial pageview
  GOVUK.analytics.trackPageview();
})();
