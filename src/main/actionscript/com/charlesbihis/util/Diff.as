package com.charlesbihis.util
{
	import com.adobe.utils.StringUtil;
	
	/**
	 * Utility class containing an implementation of the Myer's diff
	 * algorithm, generally considered to be the best general-purpose
	 * diff.
	 * 
	 * @author Charles Bihis (wwww.whoischarles.com)
	 */
	public class Diff
	{
		/**
		 * Finds the difference between two text strings.  Given the two
		 * text strings, will return an array of 'Operation' objects which
		 * will describe an efficient (no guaranteed optimal) path from
		 * original string to resulting string.
		 * 
		 * @param before The 'before' string to be diffed.
		 * @param after The 'after' string to be diffed.
		 * 
		 * @return An array of Operation objects describing the difference between the two given strings.
		 */
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
			
			// Compute the diff on the middle block.
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
		 * 
		 * Find the differences between two texts.  Assumes that the texts
		 * do not have any common prefix or suffix.
		 * 
		 * @param before The 'before' string to be diffed.
		 * @param after The 'after' string to be diffed.
		 * 
		 * @return An array of Operation objects describing the difference between the two given strings.
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
			}  // if statement
			
			// Single character string.  After the previous check, the character can't be an equality.
			if (shortText.length == 1)
			{
				diffs.push(new Operation(Operation.DELETE, before));
				diffs.push(new Operation(Operation.INSERT, after));
				return diffs;
			}  // if statement
			
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
				
				// Merge the results.
				diffs = diffsA
				diffs.push(new Operation(Operation.EQUAL, midCommon));
				for (i = 0; i < diffsB.length; i++)
				{
					diffs.push(diffsB[i]);
				}  // for loop
				return diffs;
			}  // if statement
			
			return bisect(before, after);
		}  // compute
		
		/**
		 * @private
		 * 
		 * Check to see if the two texts share a substring which is at
		 * least half the length of the longer text.
		 * 
		 * @param before The first string to check.
		 * @param after The second string to check.
		 * 
		 * @return A five-element string array containing the prefix of before,
		 * 		   the suffix of before, the prefix of after, the suffix of
		 * 		   after, and the common middle.  Null will be returned if
		 * 		   there was no match.
		 */
		private function diffHalfMatch(before:String, after:String):Array
		{
			var longText:String = before.length > after.length ? before : after;
			var shortText:String = before.length > after.length ? after : before;
			
			if (longText.length < 4 || shortText.length * 2 < longText.length)
			{
				return null;	// pointless
			}  // if statement
			
			// First, check if the second quarter is the seed for the half-match.
			var tempHalfMatch1:Array = diffHalfMatchSub(longText, shortText, (longText.length + 3) / 4);
			
			// Check again based on the third quarter.
			var tempHalfMatch2:Array = diffHalfMatchSub(longText, shortText, (longText.length + 1) / 2);
			
			var halfMatch:Array;
			if (tempHalfMatch1 == null && tempHalfMatch2 == null)
			{
				return null;
			}  // if statement
			else if (tempHalfMatch1 != null && tempHalfMatch2 != null)
			{
				halfMatch = tempHalfMatch1[4].length > tempHalfMatch2[4].length ? tempHalfMatch1 : tempHalfMatch2;	// both matched - select the longest
			}  // else-if statement
			else
			{
				halfMatch = tempHalfMatch1 != null ? tempHalfMatch1 : tempHalfMatch2;
			}  // else statement
			
			// A half-match was found, sort out the return data.
			if (before.length > after.length)
			{
				return halfMatch;
			}  // if statement
			else
			{
				var newHalfMatch:Array = new Array();
				newHalfMatch.push(halfMatch[2]);
				newHalfMatch.push(halfMatch[3]);
				newHalfMatch.push(halfMatch[0]);
				newHalfMatch.push(halfMatch[1]);
				newHalfMatch.push(halfMatch[4]);
				return newHalfMatch;
			}  // else statement
		}  // diffHalfMatch
		
		/**
		 * @private
		 * 
		 * Check to see if a substring of short text exists within the long text
		 * such that the substring is at least half the length of the long text.
		 * 
		 * @param longText The longer text.
		 * @param shortText The shorter text.
		 * @param i Start index of the quarter length substring within the long text.
		 * 
		 * @return A five-element string array containing the prefix of the long text,
		 * 		   the suffix of the long text, the prefix of the short text, the suffix
		 * 		   of the short text, and the common middle.  Null will be returned if
		 * 		   there was no match.
		 */
		private function diffHalfMatchSub(longText:String, shortText:String, i:int):Array
		{
			// Start with a 1/4 length substring at position i as a seed.
			var j:int = -1;
			var seed:String = longText.substring(i, i + longText.length / 4);
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
				}  // if statement
			}  // while loop
			
			if (bestCommon.length * 2 >= longText.length)
			{
				var halfMatchSub:Array = new Array();
				halfMatchSub.push(bestLongTextA);
				halfMatchSub.push(bestLongTextB);
				halfMatchSub.push(bestShortTextA);
				halfMatchSub.push(bestShortTextB);
				halfMatchSub.push(bestCommon);
				return halfMatchSub;
			}  // if statement
			
			return null;
		}  // diffHalfMatchSub
		
		/**
		 * @private
		 * 
		 * Find the 'middle snake' of a diff, split the problem
		 * into two and return the recursively constructed diff.
		 * 
		 * @param before The 'before' string to be diffed.
		 * @param after The 'after' string to be diffed.
		 * 
		 * @return An array of Operation objects describing the difference between the two given strings.
		 */
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
				v1[i] = -1;
				v2[i] = -1;
			}
			v1[vOffset + 1] = 0;
			v2[vOffset + 1] = 0;
			
			var delta:int = beforeLength - afterLength;
			
			// If the total number of characters is odd, then the front
			// path will collide with the reverse path.
			var front:Boolean = (delta % 2 != 0);
			
			// Offsets for start and end of k look.  Prevents mapping of space beyond the grid.
			var k1Start:int = 0;
			var k2Start:int = 0;
			var k1End:int = 0;
			var k2End:int = 0;
			var k1Offset:int;
			var k2Offset:int;
			var x1:int;
			var x2:int;
			var y1:int;
			var y2:int;
			
			for (var d:int = 0; d < maxD; d++)
			{
				// Walk the front path one step.
				for (var k1:int = -d + k1Start; k1 <= d - k1End; k1 += 2)
				{
					k1Offset = vOffset + k1;
					
					if (k1 == -d || k1 != d && v1[k1Offset - 1] < v1[k1Offset + 1])
					{
						x1 = int(v1[k1Offset + 1]);
					}  // if statement
					else
					{
						x1 = v1[k1Offset - 1] + 1;
					}  // else statement
					
					y1 = x1 - k1;
					
					while (x1 < beforeLength && y1 < afterLength && before.charAt(x1) == after.charAt(y1))
					{
						x1++;
						y1++;
					}  // while loop
					
					v1[k1Offset] = x1;
					
					if (x1 > beforeLength)
					{
						// Ran off the right of the graph.
						k1End += 2;
					}  // if statement
					else if (y1 > afterLength)
					{
						// Ran off the bottom of the graph.
						k1Start += 2;
					}  // else-if statement
					else if (front)
					{
						k2Offset = vOffset + delta - k1;
						
						if (k2Offset >= 0 && k2Offset < vLength && v2[k2Offset] != -1)
						{
							// Mirror x2 onto top-left coordinate system.
							x2 = beforeLength - int(v2[k2Offset]);
							
							if (x1 >= x2)
							{
								// Overlap detected.
								return bisectSplit(before, after, x1, y1);
							}  // if statement
						}  // if statement
					}  // else-if statement
				}  // for loop
				
				// Walk the reverse path one step.
				for (var k2:int = -d + k2Start; k2 <= d - k2End; k2 += 2)
				{
					k2Offset = vOffset + k2;
					
					if (k2 == -d || k2 != d && v2[k2Offset - 1] < v2[k2Offset + 1])
					{
						x2 = int(v2[k2Offset + 1]);
					}  // if statement
					else
					{
						x2 = v2[k2Offset - 1] + 1;
					}  // else statement
					
					y2 = x2 - k2;
					
					while (x2 < beforeLength && y2 < afterLength && before.charAt(beforeLength - x2 - 1) == after.charAt(afterLength - y2 - 1))
					{
						x2++;
						y2++;
					}  // while loop
					
					v2[k2Offset] = x2;
					
					if (x2 > beforeLength)
					{
						// Ran off the left of the graph.
						k2End += 2;
					}  // if statement
					else if (y2 > afterLength)
					{
						// Ran off the top of the graph.
						k2Start += 2;
					}  // else-if statement
					else if (!front)
					{
						k1Offset = vOffset + delta - k2;
						if (k1Offset >= 0 && k1Offset < vLength && v1[k1Offset] != -1)
						{
							x1 = int(v1[k1Offset]);
							y1 = vOffset + x1 - k1Offset;
							
							// Mirror x2 onto top-left coordinate system.
							x2 = beforeLength - x2;
							
							if (x1 >= x2)
							{
								// Overlap detected
								return bisectSplit(before, after, x1, y1);
							}  // if statement
						}  // if statement
					}  // else-if statement
				}  // for loop
			}  // for loop
			
			// The number of diffs equals the number of characters, so no commonality at all.
			var diffs:Array = new Array();
			diffs.push(new Operation(Operation.DELETE, before));
			diffs.push(new Operation(Operation.INSERT, after));
			return diffs;
		}  // bisect
		
		/**
		 * @private
		 * 
		 * Given the location of the 'middle snake', split the diff into two
		 * parts and recurse.
		 * 
		 * @param before The 'before' string to be diffed.
		 * @param after The 'after' string to be diffed.
		 * @param x The index of the split point in the 'before' string.
		 * @param y The index of the split point in the 'after' string.
		 * 
		 * @return An array of Operation objects describing the difference between the two given strings.
		 */
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
			}  // for loop
			
			return diffsA;
		}  // bisectSplit
		
		/**
		 * @private
		 * Reorder and merge like edit sections.  Merge equalities.  Any
		 * edit section can move as long as it doesn't cross an equality.
		 * 
		 * @param diffs An array of diff operation objects.
		 * 
		 * @return An array of Operation objects merged accordingly.
		 */
		private function merge(diffs:Array):Array
		{
			diffs.push(new Operation(Operation.EQUAL, ""));		// add dummy entry at the end
			
			var countDelete:int = 0;
			var countInsert:int = 0;
			var textDelete:String = "";
			var textInsert:String = "";
			
			var pointer:int = 0;
			var thisDiff:Operation = diffs[pointer] as Operation;
			var prevEqual:Operation = null;
			var commonlength:int;
			
			while (thisDiff != null)
			{
				switch(thisDiff.op)
				{
					case "INSERT":
						countInsert++;
						textInsert += thisDiff.string;
						prevEqual = null;
						break;
					case "DELETE":
						countDelete++;
						textDelete += thisDiff.string;
						prevEqual = null;
						break;
					case "EQUAL":
						if (countDelete + countInsert > 1)
						{
							var both_types:Boolean = countDelete != 0 && countInsert != 0;
							
							// Delete the offending records.
							pointer--;
							while (countDelete-- > 0)
							{
								diffs.splice(pointer, 1);
								pointer--;
							}  // while loop
							while (countInsert-- > 0)
							{
								diffs.splice(pointer, 1);
								pointer--;
							}  // while loop
							
							if (both_types)
							{
								// Factor out any common prefixes.
								commonlength = getCommonPrefixLength(textInsert, textDelete);
								if (commonlength != 0)
								{
									if (pointer > 0)
									{
										thisDiff = diffs[--pointer] as Operation;
										
										// Sanity check.
										if (thisDiff.op != Operation.EQUAL)
										{
											throw new Error("Previous diff should have been an equality");
										}  // if statement
										
										thisDiff.string += textInsert.substring(0, commonlength);
										pointer++;
									}  // if statement
									else
									{
										diffs.splice(pointer, 0, new Operation(Operation.EQUAL, textInsert.substring(0, commonlength)));
									}  // else statement
									
									textInsert = textInsert.substring(commonlength);
									textDelete = textDelete.substring(commonlength);
								}  // if statement
								
								// Factor out any common suffixes.
								commonlength = getCommonSuffixLength(textInsert, textDelete);
								if (commonlength != 0)
								{
									thisDiff = diffs[++pointer] as Operation;
									thisDiff.string = textInsert.substring(textInsert.length - commonlength) + thisDiff.string;
									textInsert = textInsert.substring(0, textInsert.length - commonlength);
									textDelete = textDelete.substring(0, textDelete.length - commonlength);
									pointer--;
								}  // if statement
							}  // if statement
							
							// Insert the merged records.
							if (textDelete.length != 0)
							{
								diffs.splice(++pointer, 0, new Operation(Operation.DELETE, textDelete));
							}  // if statement
							if (textInsert.length != 0)
							{
								diffs.splice(++pointer, 0, new Operation(Operation.INSERT, textInsert));
							}  // if statement
							
							// Step forward to the equality.
							thisDiff = pointer < diffs.length ? diffs[++pointer] as Operation : null;
						}  // if statement
						else if (prevEqual != null)
						{
							// Merge this equality with the previous one.
							prevEqual.string += thisDiff.string;
							diffs.splice(pointer, 1);
							thisDiff = diffs[--pointer] as Operation;
							pointer++;
						}  // else-if statement
						
						// Cleanup.
						countInsert = 0;
						countDelete = 0;
						textDelete = "";
						textInsert = "";
						prevEqual = thisDiff;
						break;
				}  // switch
				
				thisDiff = pointer < diffs.length - 1 ? diffs[++pointer] as Operation : null;
			}  // while
			
			if (diffs[diffs.length - 1].string.length == 0)
			{
				diffs.splice(diffs.length - 1, 1);	// remove the dummy entry at the end
			}  // if statement
			
			// Second pass.  Look for single edits surrounded on both sides
			// by equalities which can be shifted sideways to eliminate an
			// equality (e.g. A<ins>BA</ins>C -> <ins>AB</ins>AC)
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
					if (StringUtil.endsWith(thisDiff.string, prevDiff.string))
					{
						// Shift the edit over the previous equality.
						thisDiff.string = prevDiff.string + thisDiff.string.substring(0, thisDiff.string.length - prevDiff.string.length);
						nextDiff.string = prevDiff.string + nextDiff.string;
						pointer--;											// Walk past nextDiff.
						pointer--;											// Walk past thisDiff.
						pointer--;											// Walk past prevDiff.
						diffs.splice(pointer, 1);							// Delete prevDiff.
						pointer++;											// Walk past thisDiff.
						thisDiff = diffs[++pointer] as Operation;			// Walk past nextDiff.
						nextDiff = pointer < diffs.length ? diffs[++pointer] as Operation : null;
						changes = true;
					}  // if statement
					else if (StringUtil.beginsWith(thisDiff.string, nextDiff.string))
					{
						// Shift the edit over the next equality.
						prevDiff.string += nextDiff.string;
						thisDiff.string = thisDiff.string.substring(nextDiff.string.length) + nextDiff.string;
						diffs.splice(--pointer, 1);
						nextDiff = pointer < diffs.length ? diffs[++pointer] as Operation : null;
						changes = true;
					}  // else-if statement
				}  // if statement
				
				prevDiff = thisDiff;
				thisDiff = nextDiff;
				nextDiff = pointer < diffs.length ? diffs[pointer++] as Operation : null;
			}  // while
			
			// If shifts were made, the diff needs re-ordering and another shift sweep.
			if (changes)
			{
				merge(diffs);
			}  // if statement
			
			return diffs;
		}  // merge
	}  // class declaration
}  // package
