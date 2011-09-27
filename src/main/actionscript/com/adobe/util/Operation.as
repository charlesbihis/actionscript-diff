package com.adobe.util
{
	/**
	 * Class to represent a 'diff operation'.  A diff operation
	 * can be one of an equality, insertion, or deletion, accompanied
	 * by the relevant text.
	 */
	public class Operation
	{
		public static const EQUAL:String = "EQUAL";
		public static const INSERT:String = "INSERT";
		public static const DELETE:String = "DELETE";
		
		public var op:String;
		public var string:String;
		
		/**
		 * Constructor.
		 * 
		 * @param op The operation of this particular diff.
		 * @param string The relevant text for this particular diff.
		 */
		public function Operation(op:String, string:String)
		{
			this.op = op;
			this.string = string;
		}  // Operation
		
		/**
		 * Override of parent toString() method.
		 * 
		 * @return A human-readable string representing a diff operation.
		 */
		public function toString():String
		{
			return "[" + op + "] " + string;
		}  // toString
	}  // class declaration
}  // package