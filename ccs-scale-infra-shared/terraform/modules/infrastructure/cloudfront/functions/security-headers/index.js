'use strict';
exports.handler = (event, context, callback) => {

  //Get contents of response
  const response = event.Records[0].cf.response;
  const headers = response.headers;

  //Set new headers
  headers['strict-transport-security'] = [{
    key: 'Strict-Transport-Security',
    value: 'max-age=63072000; includeSubdomains; preload'
  }];
  headers['content-security-policy'] = [{
    key: 'Content-Security-Policy',
    value: "default-src blob:; img-src 'self' www.googletagmanager.com www.google-analytics.com www.google.co.uk www.google.com px.ads.linkedin.com; script-src 'self' 'unsafe-inline' blob: www.googletagmanager.com tagmanager.google.com www.google-analytics.com region1.analytics.google.com region2.analytics.google.com googleads.g.doubleclick.net snap.licdn.com www.google.co.uk ssl.google-analytics.com stats.g.doubleclick.net cdn.linkedin cdn2.gbqofs.com report.crown-comm.gbqofs.io; connect-src www.google-analytics.com www.google.co.uk region1.analytics.google.com region2.analytics.google.com cdn.linkedin stats.g.doubleclick.net cdn2.gbqofs.com report.crown-comm.gbqofs.io; font-src fonts.gstatic.com; style-src 'self' 'unsafe-inline' fonts.googleapis.com tagmanager.google.com; object-src 'none'"
  }];
  headers['x-content-type-options'] = [{
    key: 'X-Content-Type-Options',
    value: 'nosniff'
  }];
  headers['x-frame-options'] = [{
    key: 'X-Frame-Options',
    value: 'DENY'
  }];
  headers['x-xss-protection'] = [{
    key: 'X-XSS-Protection',
    value: '1; mode=block'
  }];
  headers['referrer-policy'] = [{
    key: 'Referrer-Policy',
    value: 'same-origin'
  }];

  //Return modified response
  callback(null, response);
};
