"use strict";
var AWS = require('aws-sdk');
AWS.config.update({
  region: 'eu-west-2'
})
var ssm = new AWS.SSM();

exports.handler = async (event, context, callback) => {
  //Get contents of response
  const response = event.Records[0].cf.response;
  const headers = response.headers;

  const functionName = context.functionName

  console.log('Executing.... 1');

  async function getP(){
    var params = {
      Name: '/bat/scale-bat-backend-sbx1-security-headers-csp',
      WithDecryption: false,
    };
    var request = await ssm.getParameter(params).promise();
    return request.Parameter.Value;          
  }
  
  async function getParam(headers){
    var resp = await getP();
    console.log(resp);

    headers["content-security-policy"] = [
      {
        key: "Content-Security-Policy",
        value: resp,
      },
    ];
  }

  console.log('Executing.... 3');


  await getParam(headers);

  //Set new headers
  headers["strict-transport-security"] = [
    {
      key: "Strict-Transport-Security",
      value: "max-age=63072000; includeSubdomains; preload",
    },
  ];
  headers["x-content-type-options"] = [
    {
      key: "X-Content-Type-Options",
      value: "nosniff",
    },
  ];
  headers["x-frame-options"] = [
    {
      key: "X-Frame-Options",
      value: "DENY",
    },
  ];
  headers["x-xss-protection"] = [
    {
      key: "X-XSS-Protection",
      value: "1; mode=block",
    },
  ];
  headers["referrer-policy"] = [
    {
      key: "Referrer-Policy",
      value: "same-origin",
    },
  ];

  console.log('Exiting lambda >>');
  console.log(headers);

  //Return modified response
  callback(null, response);
};
