package com.adobe.util
{
	public class Diff
	{
		public function diff(before:String, after:String):Array
		{
			// Check for null inputs.
			if (before == null || after == null)
			{
				throw new Error("Null inputs.");
			}  // if statement
			
			// Check for equality.
			var diffs:Array;
			if (before == after)
			{
				diffs = new Array();
				if (before.length != 0)
				{
					diffs.push(new Operation(Operation.EQUAL, before));
				}  // if statement
				
				return diffs;
			}  // if statement
			
			// Trim off common prefix.
			var commonPrefixLength:int = getCommonPrefixLength(before, after);
			var commonPrefix:String = before.substr(0, commonPrefixLength);
			before = before.substr(commonPrefixLength);
			after = after.substr(commonPrefixLength);
			
			// Trim off common suffix.
			var commonSuffixLength:int = getCommonSuffixLength(before, after);
			var commonSuffix:String = before.substring(before.length - commonSuffixLength);
			before = before.substring(0, before.length - commonSuffixLength);
			after = after.substring(0, after.length - commonSuffixLength);
			
			diffs = compute(before, after);
			
			// Restore the prefix and suffix.
			if (commonPrefix.length != 0)
			{
				diffs.splice(0, 0, new Operation(Operation.EQUAL, commonPrefix));
			}  // if statement
			if (commonSuffix.length != 0)
			{
				diffs.push(new Operation(Operation.EQUAL, commonSuffix));
			}  // if statement
			
			diffs = merge(diffs);
			return diffs;
		}  // diff
		
		/**
		 * @private
		 */
		private function getCommonPrefixLength(stringA:String, stringB:String):int
		{
			var count:int = Math.min(stringA.length, stringB.length);
			for (var i:int = 0; i < count; i++)
			{
				if (stringA.charAt(i) != stringB.charAt(i))
				{
					return i;
				}  // if statement
			}  // for loop
			
			return count;
		}  // getCommonPrefixLengths
		
		/**
		 * @private
		 */
		private function getCommonSuffixLength(before:String, after:String):int
		{
			var count:int = Math.min(before.length, after.length);
			for (var i:int = 1; i <= count; i++)
			{
				if (before.charAt(before.length - i) != after.charAt(after.length - i))
				{
					return i - 1;
				}  // if statement
			}  // for loop
			
			return count;
		}  // getCommonSuffixLength
		
		/**
		 * @private
		 */
		private function compute(before:String, after:String):Array
		{
			var diffs:Array = new Array();
			
			// Check if we just added text.
			if (before.length == 0)
			{
				diffs.push(new Operation(Operation.INSERT, after));
				return diffs;
			}  // if statement
			
			// Check if we just deleted text.
			if (after.length == 0)
			{
				diffs.push(new Operation(Operation.DELETE, before));
				return diffs;
			}  // if statement
			
			var longText:String = (before.length > after.length) ? before : after;
			var shortText:String = (before.length > after.length) ? after : before;
			
			// Shorter text is inside of the longer text.
			var i:int = longText.indexOf(shortText);
			if (i >= 0)
			{
				var op:String = before.length > after.length ? Operation.DELETE : Operation.INSERT;
				diffs.push(new Operation(op, longText.substring(0, i)));
				diffs.push(new Operation(Operation.EQUAL, shortText));
				diffs.push(new Operation(op, longText.substring(i + shortText.length)));
				return diffs;
			}
			
			// Single character string.  After the previous check, the character can't be an equality.
			if (shortText.length == 1)
			{
				diffs.push(new Operation(Operation.DELETE, before));
				diffs.push(new Operation(Operation.INSERT, after));
				return diffs;
			}
			
			// Cleanup.
			longText = null;
			shortText = null;
			
			// Check to see if the problem can be split in two.
			var halfMatch:Array = diffHalfMatch(before, after);
			if (halfMatch != null)
			{
				var beforeA:String = halfMatch[0];
				var beforeB:String = halfMatch[1];
				var afterA:String = halfMatch[2];
				var afterB:String = halfMatch[3];
				var midCommon:String = halfMatch[4];
				
				// Send both pairs off for separate processing.
				var diffsA:Array = diff(beforeA, afterA);
				var diffsB:Array = diff(beforeB, afterB);
				
				// Merge the results
				diffs = diffsA
				diffs.push(new Operation(Operation.EQUAL, midCommon));
				for (var i:int = 0; i < diffsB.length; i++)
				{
					diffs.push(diffsB[i]);
				}
				return diffs;
			}
			
			return bisect(before, after);
		}
		
		private function diffHalfMatch(before:String, after:String):Array
		{
			var longText:String = before.length > after.length ? before : after;
			var shortText:String = before.length > after.length ? after : before;
			
			if (longText.length < 4 || shortText.length * 2 < longText.length)
			{
				return null;	// pointless
			}
			
			// First, check if the second quarter is the seed for the half-match.
			var tempHalfMatch1:Array = diffHalfMatchSub(longText, shortText, (longText.length + 3) / 4);
			
			// Check again based on the third quarter.
			var tempHalfMatch2:Array = diffHalfMatchSub(longText, shortText, (longText.length + 1) / 2);
			
			var halfMatch:Array;
			if (tempHalfMatch1 == null && tempHalfMatch2 == null)
			{
				return null;
			}
			else if (tempHalfMatch2 == null)
			{
				halfMatch = tempHalfMatch1;
			}
			else if (tempHalfMatch1 == null)
			{
				halfMatch = tempHalfMatch2;
			}
			else
			{
				// Both matched.  Select the longest.
				halfMatch = tempHalfMatch1[4].length > tempHalfMatch2[4].length ? tempHalfMatch1 : tempHalfMatch2;
			}
			
			// A half-match was found, sort out the return data.
			if (before.length > after.length)
			{
				return halfMatch;
			}
			else
			{
				var newHalfMatch:Array = new Array();
				newHalfMatch.push(halfMatch[2]);
				newHalfMatch.push(halfMatch[3]);
				newHalfMatch.push(halfMatch[0]);
				newHalfMatch.push(halfMatch[1]);
				newHalfMatch.push(halfMatch[4]);
				return newHalfMatch;
			}
		}
		
		private function diffHalfMatchSub(longText:String, shortText:String, i:int):Array
		{
			// Start with a 1/4 length substring at position i as a seed.
			var seed:String = longText.substring(i, i + longText.length / 4);
			var j:int = -1;
			var bestCommon:String = "";
			var bestLongTextA:String = "";
			var bestLongTextB:String = "";
			var bestShortTextA:String = "";
			var bestShortTextB:String = "";
			
			while ((j = shortText.indexOf(seed, j + 1)) != -1)
			{
				var prefixLength:int = getCommonPrefixLength(longText.substring(i), shortText.substring(j));
				var suffixLength:int = getCommonSuffixLength(longText.substring(0, i), shortText.substring(0, j));
				
				if (bestCommon.length < suffixLength + prefixLength)
				{
					bestCommon = shortText.substring(j - suffixLength, j) + shortText.substring(j, j+ prefixLength);
					bestLongTextA = longText.substring(0, i - suffixLength);
					bestLongTextB = longText.substring(i + prefixLength);
					bestShortTextA = shortText.substring(0, j - suffixLength);
					bestShortTextB = shortText.substring(j + prefixLength);
				}
			}
			
			if (bestCommon.length * 2 >= longText.length)
			{
				var halfMatchSub:Array = new Array();
				halfMatchSub.push(bestLongTextA);
				halfMatchSub.push(bestLongTextB);
				halfMatchSub.push(bestShortTextA);
				halfMatchSub.push(bestShortTextB);
				halfMatchSub.push(bestCommon);
				return halfMatchSub;
			}
			else
			{
				return null;
			}
		}
		
		private function bisect(before:String, after:String):Array
		{
			// Cache the text lengths to prevent multiple calls.
			var beforeLength:int = before.length;
			var afterLength:int = after.length;
			var maxD:int = (beforeLength + afterLength + 1) / 2;
			var vOffset:int = maxD;
			var vLength:int = maxD * 2;
			
			var v1:Array = new Array(vLength);
			var v2:Array = new Array(vLength);
			for (var i:int = 0; i < vLength; i++)
			{
				//				v1.setItemAt(-1, i);
				//				v2.setItemAt(-1, i);
				v1[i] = -1;
				v2[i] = -1;
			}
			//			v1.setItemAt(0, vOffset + 1);
			//			v2.setItemAt(0, vOffset + 1);
			v1[vOffset + 1] = 0;
			v2[vOffset + 1] = 0;
			
			var delta:int = beforeLength - afterLength;
			
			// If the total number of characters is odd, then the front
			// path will collide with the reverse path.
			var front:Boolean = (delta % 2 != 0);
			
			// Offsets for start and end of k look.  Prevents mapping of space beyond the grid.
			var k1Start:int = 0;
			var k1End:int = 0;
			var k2Start:int = 0;
			var k2End:int = 0;
			
			for (var d:int = 0; d < maxD; d++)
			{
				// Walk the front path one step.
				for (var k1:int = -d + k1Start; k1 <= d - k1End; k1 += 2)
				{
					var k1Offset:int = vOffset + k1;
					var x1:int;
					
					if (k1 == -d || k1 != d && v1[k1Offset - 1] < v1[k1Offset + 1])
					{
						x1 = int(v1[k1Offset + 1]);
					}
					else
					{
						x1 = v1[k1Offset - 1] + 1;
					}
					
					var y1:int = x1 - k1;
					
					while (x1 < beforeLength && y1 < afterLength && before.charAt(x1) == after.charAt(y1))
					{
						x1++;
						y1++;
					}
					
					//					v1.setItemAt(x1, k1Offset);
					v1[k1Offset] = x1;
					
					if (x1 > beforeLength)
					{
						// Ran off the right of the graph.
						k1End += 2;
					}
					else if (y1 > afterLength)
					{
						// Ran off the bottom of the graph.
						k1Start += 2;
					}
					else if (front)
					{
						var k2Offset:int = vOffset + delta - k1;
						
						if (k2Offset >= 0 && k2Offset < vLength && v2[k2Offset] != -1)
						{
							// Mirror x2 onto top-left coordinate system.
							var x2:int = beforeLength - int(v2[k2Offset]);
							
							if (x1 >= x2)
							{
								// Overlap detected.
								return bisectSplit(before, after, x1, y1);
							}
						}
					}
				}
				
				// Walk the reverse path one step.
				for (var k2:int = -d + k2Start; k2 <= d - k2End; k2 += 2)
				{
					var k2Offset:int = vOffset + k2;
					var x2:int;
					
					if (k2 == -d || k2 != d && v2[k2Offset - 1] < v2[k2Offset + 1])
					{
						x2 = int(v2[k2Offset + 1]);
					}
					else
					{
						x2 = v2[k2Offset - 1] + 1;
					}
					
					var y2:int = x2 - k2;
					
					while (x2 < beforeLength && y2 < afterLength && before.charAt(beforeLength - x2 - 1) == after.charAt(afterLength - y2 - 1))
					{
						x2++;
						y2++;
					}
					
					//					v2.setIemAt(x2, k2Offset);
					v2[k2Offset] = x2;
					
					if (x2 > beforeLength)
					{
						// Ran off the left of the graph.
						k2End += 2;
					}
					else if (y2 > afterLength)
					{
						// Ran off the top of the graph.
						k2Start += 2;
					}
					else if (!front)
					{
						var k1Offset:int = vOffset + delta - k2;
						if (k1Offset >= 0 && k1Offset < vLength && v1[k1Offset] != -1)
						{
							var x1:int = int(v1[k1Offset]);
							var y1:int = vOffset + x1 - k1Offset;
							
							// Mirror x2 onto top-left coordinate system.
							x2 = beforeLength - x2;
							
							if (x1 >= x2)
							{
								// Overlap detected
								return bisectSplit(before, after, x1, y1);
							}  // if statement
						}  // if statement
					}  // else-if statement
				}  // reverse path for loop
			}  // for loop
			
			// The number of diffs equals the number of characters, so no commonality at all.
			var diffs:Array = new Array();
			diffs.push(new Operation(Operation.DELETE, before));
			diffs.push(new Operation(Operation.INSERT, after));
			return diffs;
		}  // bisect
		
		private function bisectSplit(before:String, after:String, x:int, y:int):Array
		{
			var beforeA:String = before.substring(0, x);
			var beforeB:String = before.substring(x);
			var afterA:String = after.substring(0, y);
			var afterB:String = after.substring(y);
			
			// Compute both diffs serially.
			var diffsA:Array = diff(beforeA, afterA);
			var diffsB:Array = diff(beforeB, afterB);
			
			for (var i:int = 0; i < diffsB.length; i++)
			{
				diffsA.push(diffsB[i]);
			}
			
			return diffsA;
		}
		
		private function merge(diffs:Array):Array
		{
			diffs.push(new Operation(Operation.EQUAL, ""));	// Add a dummy entry at the end.
			
			var count_delete:int = 0;
			var count_insert:int = 0;
			
			var text_delete:String = "";
			var text_insert:String = "";
			
			var pointer:int = 0;
			//			var thisDiff:Operation = diffs.getItemAt(pointer) as Operation;
			var thisDiff:Operation = diffs[pointer] as Operation;
			var prevEqual:Operation = null;
			var commonlength:int;
			
			while (thisDiff != null)
			{
				switch(thisDiff.op)
				{
					case "INSERT":
						count_insert++;
						text_insert += thisDiff.string;
						prevEqual = null;
						break;
					case "DELETE":
						count_delete++;
						text_delete += thisDiff.string;
						prevEqual = null;
						break;
					case "EQUAL":
						if (count_delete + count_insert > 1)
						{
							var both_types:Boolean = count_delete != 0 && count_insert != 0;
							
							// Delete the offending records.
							pointer--;
							while (count_delete-- > 0)
							{
								//								diffs.removeItemAt(pointer);
								diffs.splice(pointer, 1);
								pointer--;
							}
							while (count_insert-- > 0)
							{
								//								diffs.removeItemAt(pointer);
								diffs.splice(pointer, 1);
								pointer--;
							}
							
							if (both_types)
							{
								// Factor out any common prefixes.
								commonlength = getCommonPrefixLength(text_insert, text_delete);
								if (commonlength != 0)
								{
									if (pointer > 0)
									{
										thisDiff = diffs.getItemAt(--pointer) as Operation;
										trace(((thisDiff.op == Operation.EQUAL) ? "" : "ERROR: Previous diff should have been an equality"));
										thisDiff.string += text_insert.substring(0, commonlength);
										pointer++;
									}
									else
									{
										//										diffs.addItemAt(new Operation(Operation.EQUAL, text_insert.substring(0, commonlength)), pointer);
										diffs.splice(pointer, 0, new Operation(Operation.EQUAL, text_insert.substring(0, commonlength)));
									}
									
									text_insert = text_insert.substring(commonlength);
									text_delete = text_delete.substring(commonlength);
								}
								
								// Factor out any common suffixes.
								commonlength = getCommonSuffixLength(text_insert, text_delete);
								if (commonlength != 0)
								{
									thisDiff = diffs.getItemAt(++pointer) as Operation;
									thisDiff.string = text_insert.substring(text_insert.length - commonlength) + thisDiff.string;
									text_insert = text_insert.substring(0, text_insert.length - commonlength);
									text_delete = text_delete.substring(0, text_delete.length - commonlength);
									pointer--;
								}
							}
							
							// Insert the merged records.
							if (text_delete.length != 0)
							{
								//								diffs.addItemAt(new Operation(Operation.DELETE, text_delete), ++pointer);
								diffs.splice(++pointer, 0, new Operation(Operation.DELETE, text_delete));
							}
							if (text_insert.length != 0)
							{
								//								diffs.addItemAt(new Operation(Operation.INSERT, text_insert), ++pointer);
								diffs.splice(++pointer, 0, new Operation(Operation.INSERT, text_insert));
							}
							
							// Step forward to the equality.
							thisDiff = pointer < diffs.length ? diffs[++pointer] as Operation : null;
						}
						else if (prevEqual != null)
						{
							// Merge this equality with the previous one.
							prevEqual.string += thisDiff.string;
							//							diffs.removeItemAt(pointer);
							diffs.splice(pointer, 1);
							thisDiff = diffs[--pointer] as Operation;
							pointer++;
						}
						
						count_insert = 0;
						count_delete = 0;
						text_delete = "";
						text_insert = "";
						prevEqual = thisDiff;
						break;
				}  // switch
				
				thisDiff = pointer < diffs.length - 1 ? diffs[++pointer] as Operation : null;
			}  // while
			
			if (diffs[diffs.length - 1].string.length == 0)
			{
				//				diffs.removeItemAt(diffs.length - 1);	// Remove the dummy entry at the end.
				diffs.splice(diffs.length - 1, 1);
			}
			
			// Second pass.
			// Look for single edits surrounded on both sides by equalities
			// which can be shifted sideways to eliminate an equality.
			//
			// e.g. A<ins>BA</ins>C -> <ins>AB</ins>AC
			var changes:Boolean = false;
			
			// Reset our pointer.
			pointer = 0;
			var prevDiff:Operation = pointer < diffs.length ? diffs[pointer++] as Operation : null;
			thisDiff = pointer < diffs.length ? diffs[pointer++] as Operation : null;
			var nextDiff:Operation = pointer < diffs.length ? diffs[pointer++] as Operation : null;
			
			// Intentionally ignore the first and last element (doesn't need checking).
			while (nextDiff != null)
			{
				if (prevDiff.op == Operation.EQUAL && nextDiff.op == Operation.EQUAL)
				{
					// This is a single edit surrounded by equalities.
					if (endsWith(thisDiff.string, prevDiff.string))
					{
						// Shift the edit over the previous equality.
						thisDiff.string = prevDiff.string + thisDiff.string.substring(0, thisDiff.string.length - prevDiff.string.length);
						nextDiff.string = prevDiff.string + nextDiff.string;
						pointer--;											// Walk past nextDiff.
						pointer--;											// Walk past thisDiff.
						pointer--;											// Walk past prevDiff.
						diffs.removeItemAt(pointer);						// Delete prevDiff.
						pointer++;											// Walk past thisDiff.
						thisDiff = diffs.getItemAt(++pointer) as Operation;	// Walk past nextDiff.
						nextDiff = pointer < diffs.length ? diffs.getItemAt(++pointer) as Operation : null;
						changes = true;
					}
					else if (beginsWith(thisDiff.string, nextDiff.string))
					{
						// Shift the edit over the next equality.
						prevDiff.string += nextDiff.string;
						thisDiff.string = thisDiff.string.substring(nextDiff.string.length) + nextDiff.string;
						//						diffs.removeItemAt(--pointer);
						diffs.splice(--pointer, 1);
						nextDiff = pointer < diffs.length ? diffs.getItemAt(++pointer) as Operation : null;
						changes = true;
					}
				}
				
				prevDiff = thisDiff;
				thisDiff = nextDiff;
				nextDiff = pointer < diffs.length ? diffs[pointer++] as Operation : null;
			}  // while
			
			// If shifts were made, the diff needs re-ordering and another shift sweep.
			if (changes)
			{
				merge(diffs);
			}
			
			return diffs;
		}  // merge
		
		private function endsWith(input:String, suffix:String):Boolean
		{
			return (suffix == input.substring(input.length - suffix.length));
		}
		
		public function beginsWith(input:String, prefix:String):Boolean
		{
			return (prefix == input.substring(0, prefix.length));
		} 
	}  // class declaration
}  // package
