"use strict";
var AWS = require('aws-sdk');
AWS.config.update({
  region: 'eu-west-2'
});
var ssm = new AWS.SSM();

//Local cache of CSP header
let contentSecurityPolicy;

exports.handler = async (event, context, callback) => {
  //Get contents of response
  const response = event.Records[0].cf.response;
  const headers = response.headers;

  //Need to strip 'eu-east-1' prefix from function name
  const functionName = context.functionName.split('.').pop();
  
  async function getSSMParameter(paramName){
    const params = {
      Name: paramName,
      WithDecryption: false,
    };
    const response = await ssm.getParameter(params).promise();
    return response.Parameter.Value;          
  }
  
  async function setContentSecurityPolicy(headers){
    if(contentSecurityPolicy == undefined){
      // Parameter name is based on function name and are auto created in Terraform, so should always align
      const cspHeaderParamName = '/bat/' + functionName + '-csp';
      contentSecurityPolicy = await getSSMParameter(cspHeaderParamName);
    } 

    headers["content-security-policy"] = [
      {
        key: "Content-Security-Policy",
        value: contentSecurityPolicy,
      },
    ];
  }

  await setContentSecurityPolicy(headers);

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
