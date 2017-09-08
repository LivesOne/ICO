var fs = require("fs");
var solc = require('solc')

var genABI = function(filepath, contract) {
	                  var source = fs.readFileSync(filepath, 'utf8');
	                  var compiled = solc.compile(source);
	            
	            fs.writeFileSync(filepath+'.abi.json', compiled.contracts[':'+contract].interface);
}

var args = process.argv.slice(2);
genABI(args[0], args[1]);
