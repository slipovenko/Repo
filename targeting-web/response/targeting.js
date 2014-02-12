function Targeting(amount){
    this._amount = amount;
    this._onLoadingStartFunction = this.onAjaxLoadingStart;
    this._onLoadingFinishFunction = this.onAjaxLoadingFinish;
}

Targeting.prototype = {
    test_url : "http://10.0.3.105/test.json",
    _targetDivId : null,
    _amount : 1,
    _onLoadingStartFunction : null,
    _onLoadingFinishFunction : null,
    
    showTargetBlock : function (targetDivId){
    	this._targetDivId = targetDivId;
    	this.getTargetData(this.test_url, this.onAjaxSuccess, this.onAjaxError, this.onAjaxTimeout);
    },

    getCallParameters : function(){
        var paramStr = "";
        if (typeof this._amount !== 'undefined' && !isNaN(parseInt(this._amount))){
            paramStr += "?amount="+this._amount;
        }
    	return paramStr;
    },

    setOnLoadingStartFunction : function(onLoadingStartFunction){
        this._onLoadingStartFunction = onLoadingStartFunction;
    },

    setOnLoadingFinishFunction : function(onLoadingFinishFunction){
        this._onLoadingFinishFunction = onLoadingFinishFunction;
    },
    
    onAjaxLoadingStart : function (){
    	var targetElement = document.getElementById(this._targetDivId);
        targetElement.innerHTML = "<p>Loading ...</p>";
    },

    onAjaxLoadingFinish : function(){
    	var targetElement = document.getElementById(this._targetDivId);
        targetElement.innerHTML = "";
    },
    
    onAjaxSuccess : function(response, responseType){
        this._onLoadingFinishFunction();
    	var html = this.parseJSON(response);
    	var targetElement = document.getElementById(this._targetDivId);
    
    	//if (responseType == "json"){	
    		targetElement.innerHTML = html;
    	//}else{
    	//	targetElement.innerHTML = "<p>wrong response type: " + responseType + "</p>";
    	//}
    },
    
    onAjaxError : function(status, response, responseType){
        this._onLoadingFinishFunction();
    	var targetElement = document.getElementById(this._targetDivId);
    	targetElement.innerHTML = "<p>error: response code: " + status + "</p>";
    },
    
    onAjaxTimeout : function(url){
    	var targetElement = document.getElementById(this._targetDivId);
    	targetElement.innerHTML = "<p>timeout</p>";
    },

    onJSONParseError : function(json){
        var targetElement = document.getElementById(this._targetDivId);
        targetElement.innerHTML = "JSON parse error: <pre>"+json+"</pre>";
    },
    
    getTargetData : function(url, successFunction, errorFunction, timeoutFunction){
    	var xhr = this.getXHR();
    	url += this.getCallParameters();
    	xhr.open("GET", url, true);
    	xhr.setRequestHeader('Content-Type', "application/x-www-form-urlencoded; charset=UTF-8");
    	xhr.timeout = 2000; //2 sec
        var targetObj = this;
    	xhr.onreadystatechange = function (){
    		if (xhr.readyState == 4){
    			if (xhr.status == 200){ //success
    				successFunction.call(targetObj, xhr.response, xhr.responseType);
    			}else{ //error
    				errorFunction.call(targetObj, xhr.status, xhr.response, xhr.responseType);
    			}
    		}
    	}
    	xhr.ontimeout = function (){
    		if (typeof timeoutFunction !== 'undefined'){
    			timeoutFunction.call(targetObj, url);
    		}else{
    			errorFunction.call(targetObj, '408' /* request timeout */, '', '');
    		}
    	}
        this._onLoadingStartFunction.call(this);
    	xhr.send(url);
    },
    //from jquery
    // Functions to create xhrs
    createStandardXHR : function() {
    	try {
    		return new window.XMLHttpRequest();
    	} catch( e ) {}
    },

    createActiveXHR : function() {
    	try {
    		return new window.ActiveXObject( "Microsoft.XMLHTTP" );
    	} catch( e ) {}
    },
    
    getXHR : function(){
    	return (window.ActiveXObject !== undefined ?
    	    this.createActiveXHR()
    	    :
    	    // For all other browsers, use the standard XMLHttpRequest object
    	    this.createStandardXHR());
    },

    parseJSON : function(json){
        var data = "";
        data = this.parseJSONToObject(json);
    	
    	var html = "";
    	for (i=0; i<data.length; i++){
    		var obj = data[i];
    		var html_link = '<a href="';
    		var link_present = false;
    		
    		html += '<div class="_targeting_block">';
    		
    		if (typeof obj.link !== 'undefined'){
    			link_present = true;
    			html_link += obj.link.url + '">';
    		}
    		
    		html += '<div class="_targeting_img">';
    		if (typeof obj.image !== 'undefined'){
    			if (link_present){
    				html += html_link;
    			}
    			html += '<img src="' + obj.image + '"/>';
    			if (link_present){
    				html += '</a>';
    			}
    		}
    		html += '</div>';
    		
    		html += '<div class="_targeting_link">';
    		if (link_present){
    			html += html_link + obj.link.text + '</a>';
    		}
    		html += '</div>';
    		
    		html += '<div class="_targeting_text">';
    		if (typeof obj.text !== 'undefined'){
    			if (link_present){
    				html += html_link;
    			}
    			html += obj.text;
    			if (link_present){
    				html += '</a>';
    			}
    		}
    		html += '</div>';
    		html += '</div>'; //_targeting_block
    	}
    	return html;
    },

    //function from jquery
    parseJSONToObject : function(data){
    	// Attempt to parse using the native JSON parser first
    	if ( window.JSON && window.JSON.parse ) {
    		// Support: Android 2.3
    		// Workaround failure to string-cast null input
            try{
    		    return window.JSON.parse( data + "" );
            }catch(e){
                this.onJSONParseError(data);
            }
    	}
    	var requireNonComma,
    		depth = null,
    		str = this.trim( data + "" );
    
    	// Guard against invalid (and possibly dangerous) input by ensuring that nothing remains
    	// after removing valid tokens
    	return str && !this.trim( str.replace( rvalidtokens, function( token, comma, open, close ) {
    
    		// Force termination if we see a misplaced comma
    		if ( requireNonComma && comma ) {
    			depth = 0;
    		}
    
    		// Perform no more replacements after returning to outermost depth
    		if ( depth === 0 ) {
    			return token;
    		}
    
    		// Commas must not follow "[", "{", or ","
    		requireNonComma = open || comma;
    
    		// Determine new depth
    		// array/object open ("[" or "{"): depth += true - false (increment)
    		// array/object close ("]" or "}"): depth += false - true (decrement)
    		// other cases ("," or primitive): depth += true - true (numeric cast)
    		depth += !close - !open;
    
    		// Remove this token
    		return "";
    	}) ) ?
    		( Function( "return " + str ) )() :
    		this.onJSONParseError( "Invalid JSON: " + data );
    },
    
    //from jQuery
	trim: "".trim && !"".trim.call("\uFEFF\xA0") ?
		function( text ) {
			return text == null ?
				"" :
				"".trim.call( text );
		} :

		// Otherwise use our own trimming functionality
		function( text ) {
			return text == null ?
				"" :
				( text + "" ).replace( /^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g, "" );
	},
}
