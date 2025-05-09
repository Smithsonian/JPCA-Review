<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron"
    xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    queryBinding="xslt2">
    <sch:ns uri="http://www.w3.org/1999/xlink" prefix="xlink"/>
    <sch:ns uri="urn:isbn:1-931666-22-9" prefix="ead2002"/>
    
    <sch:title>First set of JPCA tests (should also add some tests for the tests!)</sch:title>
     
    <!-- tests to add:
        Any duplicate subjects
        Any duplicate agent-persons
        ???
    -->

    <sch:let name="c" value="'^c$|^c[0|1]'"/> 
    
    <!-- rights note test -->
    <sch:pattern>
        <sch:rule context="ead2002:userestrict[ead2002:head = 'Rights Statement']">
            <sch:let name="id" value="../@id"/>
            <sch:let name="preferred-text" value="'Some or all of the photos in this folder may be subject to copyright or other intellectual property rights.'"/>
            <sch:let name="current-text" value="ead2002:note/ead2002:p/normalize-space()"/>
            <sch:assert test="$current-text eq $preferred-text">
                The rights statement for, <xsl:value-of select="$id"/>, is unexpected: <xsl:value-of select="$current-text"/>
            </sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <!-- level test -->
    <sch:pattern>
        <sch:rule context="ead2002:*[matches(local-name(), $c)]/@level">
            <sch:let name="id" value="../@id"/>
            <sch:assert test=". = ('file', 'item', 'otherlevel', 'series', 'subseries')">
                The level attribute for, <xsl:value-of select="$id"/>, is unexpected.  Please investigate
            </sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <!-- title test -->
    <!-- but maybe this is okay in Ebony Fashion Fair, etc. 
    <sch:pattern>
        <sch:rule context="ead2002:*[matches(local-name(), $c)]/ead2002:did 
            | ead2002:archdesc/ead2002:did">
            <sch:let name="id" value="(../@id, ../../ead2002:eadheader/ead2002:eadid)[1]"/>
            <sch:assert test="ead2002:unittitle">
                The following component, <xsl:value-of select="$id"/>, is missing a title. While perfectly valid for archival description, that is unusual for the JPCA project's data model.  Check it out!
            </sch:assert>
        </sch:rule>
    </sch:pattern>
    -->
    
    <!-- ensure that terminal components have containers -->
    <sch:pattern id="terminal-components">
        <sch:rule context="ead2002:*[matches(local-name(), $c)][not(*[matches(local-name(), $c)])]">
            <sch:let name="id" value="@id"/>
            <sch:assert test="ead2002:did/ead2002:container">
                Hold up. This terminal component, <xsl:value-of select="$id"/>, is missing a container element.
            </sch:assert>
        </sch:rule>
    </sch:pattern>
    
    <!-- ensure that components with containers do NOT also have descendants with containers, nor siblings with descendants with containers -->
    <sch:pattern>
        <sch:rule context="ead2002:*[matches(local-name(), $c)][ead2002:did/ead2002:container]">
            <sch:let name="id" value="@id"/>
            <sch:report test="../*[descendant::ead2002:*/ead2002:did/ead2002:container]">
                Nope. This component, <xsl:value-of select="$id"/> which is connected to a container, also has at least one descendant that also has associated containers.  Check it out!
            </sch:report>
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern>
        <!-- but no need to test for the EAD element being published, since ASpace will always export that, and the rest of the pipeline does not support the audience attribute -->
        <sch:rule context="ead2002:*[@audience='internal'][not(local-name() eq 'ead')]">
            <sch:let name="id" value="@id"/>
            <sch:report test="true()">Uh oh. This component, <xsl:value-of select="($id, local-name())[1]"/>, is not published in ArchivesSpace.</sch:report>
        </sch:rule>
        
        <!-- temp override, until we update the userestrict Rights exports -->
        <sch:rule context="ead2002:*[local-name() ne 'userestrict'][starts-with(@id, 'aspace_')]">
            <sch:let name="id" value="@id"/>
            <sch:report test="true()">Uh oh -- aspace_ alert! This component, <xsl:value-of select="$id"/>, has an ID attribute that starts with "aspace_".</sch:report>
        </sch:rule>
    </sch:pattern>

    <!--
        <unittitle>Folder 1 of N</unittitle> tests
     -->
    <sch:pattern>
        <!-- first, look for Folder X of [blank] -->
        <sch:rule context="ead2002:*[ead2002:did/ead2002:unittitle/matches(., '^Folder \d{1,4} of $')]">
            <sch:let name="id" value="@id"/>
            <sch:report test="true()">
                Looks like a placeholder.  Check out <xsl:value-of select="$id"/>. There appears to be an issue with the current title, which is: <xsl:value-of select="ead2002:did/ead2002:unittitle"/>
            </sch:report>
        </sch:rule>
        
        <sch:rule context="ead2002:*[matches(local-name(), $c)][matches(ead2002:*[matches(local-name(), $c)][1]/ead2002:did/ead2002:unittitle[1], '^Folder 1 of \d{1,4}$')]">
            <sch:let name="id" value="@id"/>
            <sch:let name="last-folder" value="replace(ead2002:*[matches(local-name(), $c)][1]/ead2002:did/ead2002:unittitle[1], 'Folder 1 of ', '') => number()"/>
            <sch:let name="component-count" value="count(ead2002:*[matches(local-name(), $c)])"/>
            
            <!-- simple test -->
            <sch:assert test="$component-count eq $last-folder">Whoopsie. The last folder in component group <xsl:value-of select="$id"/> is <xsl:value-of select="$last-folder"/>, but the total component count is, <xsl:value-of select="$component-count"/>.  Those values should match.</sch:assert>
            
            <!-- more exhaustive test, to ensure that all the numbers are in order... e.g., no instances of 1, 3, 2. -->
            <sch:let name="expressed-range" value="if ($last-folder castable as xs:integer) then 1 to xs:integer($last-folder) else 0"/>
            <sch:let name="folder-range" value="for $n in ead2002:*[matches(local-name(), $c)]/ead2002:did/ead2002:unittitle/substring-after(substring-before(., ' of'), 'Folder ') 
                return if ($n castable as xs:integer) then xs:integer($n) else 0"/>
            <sch:assert test="count($expressed-range) eq count($folder-range) and (
                every $n in for-each-pair($folder-range, $expressed-range, deep-equal#2) satisfies $n
                )">Yep, there's a problem with the folder range expression of component group <xsl:value-of select="$id"/>. Compare <xsl:value-of select="$folder-range"/> versus <xsl:value-of select="$expressed-range"/></sch:assert>
            
            <!-- one more test to check and make sure that every last-folder in the same component group match what's expected for the range -->
            <sch:let name="all-last-folders" value="for $n in ead2002:*[matches(local-name(), $c)]/ead2002:did/ead2002:unittitle/substring-after(., 'of ') 
                return if ($n castable as xs:integer) then xs:integer($n) else 0"/>
            <sch:assert test="every $n in $all-last-folders satisfies $n eq $last-folder">Range Error: There's a problem with the folder range expression of component group <xsl:value-of select="$id"/>.  Not all of the values -- i.e, <xsl:value-of select="filter(distinct-values($all-last-folders), function($x){not($x eq $last-folder)})"/> -- end in <xsl:value-of select="$last-folder"/></sch:assert>
        </sch:rule>
    </sch:pattern>
    
    
    <!-- separate and combine, later -->
    <sch:pattern id="dates">
        <sch:let name="qualifier" value="'[~%?]?'"/>
        <sch:let name="months" value="1 to 12"/>
        <sch:let name="seasons" value="21 to 41"/>
        <sch:let name="Y" value="'[+-]?(([0-9X])([0-9X]{3})|([1-9X])([0-9X]{4,9}))'"/>
        <sch:let name="M"
            value="'(' || (string-join(for $x in ($months) return format-number($x, '00'), '|')) || '|([0-1]X)|' || 'X[0-9])'"/>
        <sch:let name="M_S"
            value="'(' || (string-join(for $x in ($months, $seasons) return format-number($x, '00'), '|')) || '|([0-1]X)|' || 'X[0-9])'"/>
        <sch:let name="D" value="'(([0X][1-9X])|([012X][0-9X])|([3X][0-1X]))'"/>
        <sch:let name="T"
            value="'[T| ](0[0-9]|1[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9]|60)(?:Z|[+-](?:2[0-3]|[01][0-9]):[0-5][0-9])$'"/>
        <sch:let name="iso8601-regex"
            value="concat('^', $qualifier, $Y, $qualifier, '$','|', '^', $qualifier, $Y, $qualifier, '-', $qualifier, $M_S, $qualifier, '$', '|', '^', $qualifier, $Y, $qualifier, '-', $qualifier, $M, $qualifier, '-', $qualifier, $D, $qualifier, '$', '|', '^', $qualifier, $Y, $qualifier, '-', $qualifier, $M, $qualifier, '-', $qualifier, $D, $qualifier, $T, '$')"/>
        <sch:rule context="ead2002:unitdate[@normal[not(matches(., '\.\.|/'))]]">
            <sch:assert test="every $d in (@normal[not(matches(., '\.\.|/'))]) satisfies matches($d, $iso8601-regex)">The <sch:emph>normal</sch:emph> attribute of <sch:name/> must match the TS-EAS subprofile of valid ISO 8601 dates.</sch:assert>
        </sch:rule>
    </sch:pattern>
    <sch:pattern id="date-range-tests">
        <sch:rule context="ead2002:unitdate[@normal[matches(., '\.\.|/')]]">
            <sch:assert test="every $d in (tokenize(@normal, '(\.\.)|(/)')[normalize-space()]) satisfies matches($d, $iso8601-regex)">All <sch:emph>normal</sch:emph> attributes in a valid date range must match the TS-EAS subprofile of valid ISO 8601 dates.</sch:assert>
            <sch:report test="count(tokenize(@normal, '(\.\.)|(/)'))&gt;=3">This date expression has too many range operators. Only a single "/" or ".." is permitted.</sch:report>
        </sch:rule>
    </sch:pattern>
    <sch:pattern id="leap-year-tests">
        <sch:rule context="ead2002:unitdate[matches(replace(@normal, '[%~?]', ''), '-02-')]">
            <sch:let name="year-string" value="substring-before(@normal, '-') =&gt; replace('[+%~?]', '')"/>
            <sch:let name="year" value="if ($year-string castable as xs:gYear) then xs:integer($year-string) else false()"/>
            <sch:let name="leap-year"
                value="if ($year) then (($year mod 4 = 0 and $year mod 100 != 0) or $year mod 400 = 0) else false()"/>
            <sch:report test="matches(replace(@normal, '[%~?]', ''), '-02-30|-02-31')">February dates cannot have a day value of 30 or 31. Check the value of the "normal" attribute.</sch:report>
            <sch:report test="$year and not($leap-year) and matches(replace(@normal, '[%~?]', ''), '-02-29')">February 29th may only be encoded for leap years. The year encoded in the "normal" attribute, <xsl:value-of select="$year-string"/>, however, is not a valid leap year.</sch:report>
        </sch:rule>
    </sch:pattern>
    <sch:pattern id="simple-date-range-comparisons">
        <sch:rule context="ead2002:unitdate[matches(@normal, '[0-9]/[0-9]')]">
            <sch:let name="begin_date" value="substring-before(@normal, '/')"/>
            <sch:let name="end_date" value="substring-after(@normal, '/')"/>
            <sch:let name="testable_dates"
                value="every $d in ($begin_date, $end_date) satisfies ($d castable as xs:date or $d castable as xs:dateTime or $d castable as xs:gYear or $d castable as xs:gYearMonth)"/>
            <sch:assert test="if ($testable_dates) then $end_date >= $begin_date else true()">
                The normal attribute value for this field needs to be updated. The first date, <xsl:value-of select="$begin_date"/>, is encoded as occurring <sch:emph>before</sch:emph> the end date, <xsl:value-of select="$end_date"/>
            </sch:assert>
        </sch:rule>
        <sch:rule context="ead2002:unitdate[matches(@normal, '[0-9]\.\.[0-9]')]">
            <sch:let name="begin_date" value="substring-before(@normal, '..')"/>
            <sch:let name="end_date" value="substring-after(@normal, '..')"/>
            <sch:let name="testable_dates"
                value="every $d in ($begin_date, $end_date) satisfies ($d castable as xs:date or $d castable as xs:dateTime or$d castable as xs:gYear or $d castable as xs:gYearMonth)"/>
            <sch:assert test="if ($testable_dates) then $end_date gt $begin_date else true()">
                The normal attribute value for this field needs to be updated. The first date, <xsl:value-of select="$begin_date"/>, is encoded as occurring <sch:emph>before</sch:emph> the end date, <xsl:value-of select="$end_date"/>
            </sch:assert>
        </sch:rule>
    </sch:pattern>
</sch:schema>