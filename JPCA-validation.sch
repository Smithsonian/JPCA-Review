<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron"
    xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" defaultPhase="container-checks"
    queryBinding="xslt3">
    <ns uri="http://www.w3.org/1999/xlink" prefix="xlink"/>
    <ns uri="urn:isbn:1-931666-22-9" prefix="ead2002"/>

    <title>First set of JPCA tests (should also add some tests for the tests!)</title>

    <!-- tests to add:
        Any duplicate subjects
        Any duplicate agent-persons
        ???
    -->

    <!-- 
    collections to exclude / different validation phases :
        /repositories/2/resources/7        A/V:      2023.M.24-AV
        /repositories/2/resources/43       Serials:  2023.M.24-PUB
    -->

    <let name="c" value="'^c$|^c[0|1]'"/>

    <phase id="container-checks">
        <active pattern="container"/>
    </phase>

    <pattern id="container">
        <rule context="ead2002:*[matches(local-name(), $c)][ead2002:did/ead2002:container]">
            <let name="id" value="@id"/>
            <let name="sequence" value="ead2002:did/ead2002:container[@label]"/>
            <let name="duplicates" value="$sequence[index-of($sequence, .)[2]]"/>

            <report test="count(ead2002:did/ead2002:container[@parent]) gt 1"> Howdy. This
                component, <xsl:value-of select="$id"/>, which is connected to a container, has
                multiple top containers. Check those box+folder numbers: <xsl:value-of select="
                        string-join((for $x in (ead2002:did/ead2002:container[@label])
                        return
                            $x/@type || ' ' || $x), '; ')"/>
            </report>

            <report test="$duplicates"> Woah. Duplicate top container values for: <xsl:value-of
                    select="$duplicates"/> at ref ID = <xsl:value-of select="$id"/>
            </report>
        </rule>
    </pattern>

    <!-- rights note test -->
    <pattern>
        <rule context="ead2002:userestrict[ead2002:head = 'Rights Statement']">
            <let name="id" value="../@id"/>
            <let name="preferred-text"
                value="'Some or all of the photos in this folder may be subject to copyright or other intellectual property rights.'"/>
            <let name="current-text" value="ead2002:note/ead2002:p/normalize-space()"/>
            <assert test="$current-text eq $preferred-text"> The rights statement for, <xsl:value-of
                    select="$id"/>, is unexpected: <xsl:value-of select="$current-text"/>
            </assert>
        </rule>
    </pattern>

    <!-- level test -->
    <pattern>
        <rule context="ead2002:*[matches(local-name(), $c)]/@level">
            <let name="id" value="../@id"/>
            <assert test=". = ('file', 'item', 'otherlevel', 'series', 'subseries')"> The level
                attribute for, <xsl:value-of select="$id"/>, is unexpected. Please investigate
            </assert>
        </rule>
    </pattern>

    <!-- title test -->
    <!-- but maybe this is okay in Ebony Fashion Fair, etc. 
    <pattern>
        <rule context="ead2002:*[matches(local-name(), $c)]/ead2002:did 
            | ead2002:archdesc/ead2002:did">
            <let name="id" value="(../@id, ../../ead2002:eadheader/ead2002:eadid)[1]"/>
            <assert test="ead2002:unittitle">
                The following component, <xsl:value-of select="$id"/>, is missing a title. While perfectly valid for archival description, that is unusual for the JPCA project's data model.  Check it out!
            </assert>
        </rule>
    </pattern>
    -->

    <!-- ensure that terminal components have containers -->
    <pattern id="terminal-components">
        <rule context="ead2002:*[matches(local-name(), $c)][not(*[matches(local-name(), $c)])]">
            <let name="id" value="@id"/>
            <assert test="ead2002:did/ead2002:container"> Hold up. This terminal component,
                    <xsl:value-of select="$id"/>, is missing a container element. </assert>
        </rule>
    </pattern>

    <!-- ensure that components with containers do NOT also have descendants with containers, nor siblings with descendants with containers -->
    <pattern>
        <rule context="ead2002:*[matches(local-name(), $c)][ead2002:did/ead2002:container]">
            <let name="id" value="@id"/>
            <report test="../*[descendant::ead2002:*/ead2002:did/ead2002:container]"> Nope. This
                component, <xsl:value-of select="$id"/> which is connected to a container, also has
                at least one descendant that also has associated containers. Check it out! </report>
        </rule>
    </pattern>

    <pattern>
        <!-- but no need to test for the EAD element being published, since ASpace will always export that, and the rest of the pipeline does not support the audience attribute -->
        <rule context="ead2002:*[@audience = 'internal'][not(local-name() eq 'ead')]">
            <let name="id" value="@id"/>
            <report test="true()">Uh oh. This component, <xsl:value-of
                    select="($id, local-name())[1]"/>, is not published in ArchivesSpace.</report>
        </rule>

        <!-- temp override, until we update the userestrict Rights exports -->
        <rule context="ead2002:*[local-name() ne 'userestrict'][starts-with(@id, 'aspace_')]">
            <let name="id" value="@id"/>
            <report test="true()">Uh oh -- aspace_ alert! This component, <xsl:value-of select="$id"
                />, has an ID attribute that starts with "aspace_".</report>
        </rule>
    </pattern>

    <!--
        <unittitle>Folder 1 of N</unittitle> tests
     -->
    <pattern>
        <!-- first, look for Folder X of [blank] -->
        <rule context="ead2002:*[ead2002:did/ead2002:unittitle/matches(., '^Folder \d{1,4} of $')]">
            <let name="id" value="@id"/>
            <report test="true()"> Looks like a placeholder. Check out <xsl:value-of select="$id"/>.
                There appears to be an issue with the current title, which is: <xsl:value-of
                    select="ead2002:did/ead2002:unittitle"/>
            </report>
        </rule>

        <rule
            context="ead2002:*[matches(local-name(), $c)][matches(ead2002:*[matches(local-name(), $c)][1]/ead2002:did/ead2002:unittitle[1], '^Folder 1 of \d{1,4}$')]">
            <let name="id" value="@id"/>
            <let name="last-folder"
                value="replace(ead2002:*[matches(local-name(), $c)][1]/ead2002:did/ead2002:unittitle[1], 'Folder 1 of ', '') => number()"/>
            <let name="component-count" value="count(ead2002:*[matches(local-name(), $c)])"/>

            <!-- simple test -->
            <assert test="$component-count eq $last-folder">Whoopsie. The last folder in component
                group <xsl:value-of select="$id"/> is <xsl:value-of select="$last-folder"/>, but the
                total component count is, <xsl:value-of select="$component-count"/>. Those values
                should match.</assert>

            <!-- more exhaustive test, to ensure that all the numbers are in order... e.g., no instances of 1, 3, 2. -->
            <let name="expressed-range" value="
                    if ($last-folder castable as xs:integer) then
                        1 to xs:integer($last-folder)
                    else
                        0"/>
            <let name="folder-range" value="
                    for $n in ead2002:*[matches(local-name(), $c)]/ead2002:did/ead2002:unittitle/substring-after(substring-before(., ' of'), 'Folder ')
                    return
                        if ($n castable as xs:integer) then
                            xs:integer($n)
                        else
                            0"/>
            <assert test="
                    count($expressed-range) eq count($folder-range) and (
                    every $n in for-each-pair($folder-range, $expressed-range, deep-equal#2)
                        satisfies $n
                    )">Yep, there's a problem with the folder range expression of
                component group <xsl:value-of select="$id"/>. Compare <xsl:value-of
                    select="$folder-range"/> versus <xsl:value-of select="$expressed-range"
                /></assert>

            <!-- one more test to check and make sure that every last-folder in the same component group match what's expected for the range -->
            <let name="all-last-folders" value="
                    for $n in ead2002:*[matches(local-name(), $c)]/ead2002:did/ead2002:unittitle/substring-after(., 'of ')
                    return
                        if ($n castable as xs:integer) then
                            xs:integer($n)
                        else
                            0"/>
            <assert test="
                    every $n in $all-last-folders
                        satisfies $n eq $last-folder">Range Error: There's a problem
                with the folder range expression of component group <xsl:value-of select="$id"/>.
                Not all of the values -- i.e, <xsl:value-of select="
                        filter(distinct-values($all-last-folders), function ($x) {
                            not($x eq $last-folder)
                        })"/> -- end in <xsl:value-of select="$last-folder"
                /></assert>
        </rule>
    </pattern>
    
    <!--
        <unittitle>Folder Nof ***or*** ofN</unittitle> tests
     -->
    <pattern>
        <rule context="ead2002:*[ead2002:did/ead2002:unittitle/matches(., '^Folder \d{1,4}of')
            or 
            ead2002:did/ead2002:unittitle/matches(., 'of\d{1,4}')]">
            <let name="id" value="@id"/>
            <report test="true()"> We've got a spacing issue! Check out <xsl:value-of select="$id"/>.
                There appears to be an issue with the current title, which is: <xsl:value-of
                    select="ead2002:did/ead2002:unittitle"/>
            </report>
        </rule>
    </pattern>
    
    <!-- multiple note tests -->
    <!-- beyond physdesc and scopecontent, what else is needed here? -->
    <!-- do we also need to add a filter here based on the level, e.g. file vs. series? -->
    <pattern>
        <rule context="ead2002:*[matches(local-name(), $c)]">
            <let name="id" value="@id"/>          
            <let name="did-notes-that-should-not-repeat" value="('physdesc')"/>
            <let name="non-did-notes-that-should-not-repeat" value="('scopecontent')"/>
            <report test="ead2002:did/*[local-name() = $did-notes-that-should-not-repeat][2]"> Unfortunately, this component has more than one identification note of the same type. Check out <xsl:value-of select="$id"/>.</report>
            <report test="*[local-name() = $non-did-notes-that-should-not-repeat][2]"> Unfortunately, this component has more than one narrative note of the same type. Check out <xsl:value-of select="$id"/>.</report>
        </rule>
    </pattern>


    <!-- separate and combine, later (no need to make these checks on every run, most likely) -->
    <pattern id="dates">
        <let name="qualifier" value="'[~%?]?'"/>
        <let name="months" value="1 to 12"/>
        <let name="seasons" value="21 to 41"/>
        <let name="Y" value="'[+-]?(([0-9X])([0-9X]{3})|([1-9X])([0-9X]{4,9}))'"/>
        <let name="M" value="
                '(' || (string-join(for $x in ($months)
                return
                    format-number($x, '00'), '|')) || '|([0-1]X)|' || 'X[0-9])'"/>
        <let name="M_S" value="
                '(' || (string-join(for $x in ($months, $seasons)
                return
                    format-number($x, '00'), '|')) || '|([0-1]X)|' || 'X[0-9])'"/>
        <let name="D" value="'(([0X][1-9X])|([012X][0-9X])|([3X][0-1X]))'"/>
        <let name="T"
            value="'[T| ](0[0-9]|1[0-9]|2[0-3]):([0-5][0-9]):([0-5][0-9]|60)(?:Z|[+-](?:2[0-3]|[01][0-9]):[0-5][0-9])$'"/>
        <let name="iso8601-regex"
            value="concat('^', $qualifier, $Y, $qualifier, '$', '|', '^', $qualifier, $Y, $qualifier, '-', $qualifier, $M_S, $qualifier, '$', '|', '^', $qualifier, $Y, $qualifier, '-', $qualifier, $M, $qualifier, '-', $qualifier, $D, $qualifier, '$', '|', '^', $qualifier, $Y, $qualifier, '-', $qualifier, $M, $qualifier, '-', $qualifier, $D, $qualifier, $T, '$')"/>
        <rule context="ead2002:unitdate[@normal[not(matches(., '\.\.|/'))]]">
            <assert test="
                    every $d in (@normal[not(matches(., '\.\.|/'))])
                        satisfies matches($d, $iso8601-regex)">The <emph>normal</emph>
                attribute of <name/> must match the TS-EAS subprofile of valid ISO 8601
                dates.</assert>
        </rule>
    </pattern>
    <pattern id="date-range-tests">
        <rule context="ead2002:unitdate[@normal[matches(., '\.\.|/')]]">
            <assert test="
                    every $d in (tokenize(@normal, '(\.\.)|(/)')[normalize-space()])
                        satisfies matches($d, $iso8601-regex)">All <emph>normal</emph>
                attributes in a valid date range must match the TS-EAS subprofile of valid ISO 8601
                dates.</assert>
            <report test="count(tokenize(@normal, '(\.\.)|(/)')) &gt;= 3">This date expression has
                too many range operators. Only a single "/" or ".." is permitted.</report>
        </rule>
    </pattern>
    <pattern id="leap-year-tests">
        <rule context="ead2002:unitdate[matches(replace(@normal, '[%~?]', ''), '-02-')]">
            <let name="year-string"
                value="substring-before(@normal, '-') =&gt; replace('[+%~?]', '')"/>
            <let name="year" value="
                    if ($year-string castable as xs:gYear) then
                        xs:integer($year-string)
                    else
                        false()"/>
            <let name="leap-year" value="
                    if ($year) then
                        (($year mod 4 = 0 and $year mod 100 != 0) or $year mod 400 = 0)
                    else
                        false()"/>
            <report test="matches(replace(@normal, '[%~?]', ''), '-02-30|-02-31')">February dates
                cannot have a day value of 30 or 31. Check the value of the "normal"
                attribute.</report>
            <report
                test="$year and not($leap-year) and matches(replace(@normal, '[%~?]', ''), '-02-29')"
                >February 29th may only be encoded for leap years. The year encoded in the "normal"
                attribute, <xsl:value-of select="$year-string"/>, however, is not a valid leap
                year.</report>
        </rule>
    </pattern>
    <pattern id="simple-date-range-comparisons">
        <rule context="ead2002:unitdate[matches(@normal, '[0-9]/[0-9]')]">
            <let name="begin_date" value="substring-before(@normal, '/')"/>
            <let name="end_date" value="substring-after(@normal, '/')"/>
            <let name="testable_dates" value="
                    every $d in ($begin_date, $end_date)
                        satisfies ($d castable as xs:date or $d castable as xs:dateTime or $d castable as xs:gYear or $d castable as xs:gYearMonth)"/>
            <assert test="
                    if ($testable_dates) then
                        $end_date >= $begin_date
                    else
                        true()"> The normal attribute value for this field needs to be
                updated. The first date, <xsl:value-of select="$begin_date"/>, is encoded as
                occurring <emph>before</emph> the end date, <xsl:value-of select="$end_date"/>
            </assert>
        </rule>
        <rule context="ead2002:unitdate[matches(@normal, '[0-9]\.\.[0-9]')]">
            <let name="begin_date" value="substring-before(@normal, '..')"/>
            <let name="end_date" value="substring-after(@normal, '..')"/>
            <let name="testable_dates" value="
                    every $d in ($begin_date, $end_date)
                        satisfies ($d castable as xs:date or $d castable as xs:dateTime or $d castable as xs:gYear or $d castable as xs:gYearMonth)"/>
            <assert test="
                    if ($testable_dates) then
                        $end_date gt $begin_date
                    else
                        true()"> The normal attribute value for this field needs to be
                updated. The first date, <xsl:value-of select="$begin_date"/>, is encoded as
                occurring <emph>before</emph> the end date, <xsl:value-of select="$end_date"/>
            </assert>
        </rule>
    </pattern>
</schema>
