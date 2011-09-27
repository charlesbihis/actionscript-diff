package com.adobe.util
{
	public class Operation
	{
		public static const EQUAL:String = "EQUAL";
		public static const INSERT:String = "INSERT";
		public static const DELETE:String = "DELETE";
		
		public var op:String;
		public var string:String;
		
		public function Operation(op:String, string:String)
		{
			this.op = op;
			this.string = string;
		}
		
		public function toString():String
		{
			return op + " " + string;
		}
	}
}