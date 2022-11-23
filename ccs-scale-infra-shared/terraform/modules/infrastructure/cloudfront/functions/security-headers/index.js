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
    value: "default-src 'none'; img-src 'self' www.googletagmanager.com https://www.google-analytics.com; script-src 'self' 'unsafe-inline' https://www.googletagmanager.com https://tagmanager.google.com https://www.google-analytics.com https://ssl.google-analytics.com cdn2.gbqofs.com report.crown-comm.gbqofs.io; connect-src https://www.google-analytics.com cdn2.gbqofs.com report.crown-comm.gbqofs.io; font-src fonts.gstatic.com; style-src 'self' 'unsafe-inline' fonts.googleapis.com https://tagmanager.google.com; object-src 'none'"
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
