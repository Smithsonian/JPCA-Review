<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:ead2002="urn:isbn:1-931666-22-9" xmlns:mdc="http://mdc"
    exclude-result-prefixes="xs math ead2002 mdc"
    version="3.0">
    
    <xsl:output method="text" encoding="UTF-8"/>
    
    <xsl:mode on-no-match="shallow-skip"/>
    
    <xsl:param name="c" select="'^c$|^c[0|1]'"/>
    <xsl:param name="delim" select="','" />
    <xsl:param name="quote" select="'&quot;'" />
    <xsl:param name="break" select="'&#xA;'" />
    
    <xsl:variable name="EADID" select="ead2002:ead/ead2002:archdesc/ead2002:did/ead2002:unitid[not(@type)]/normalize-space()"/>
    <xsl:variable name="EADTitle" select="ead2002:ead/ead2002:archdesc/ead2002:did/ead2002:unittitle[1]/normalize-space()"/>
    
    <!-- make the headers dynamic... later -->
    <xsl:template match="/">
        <!-- this file has headers -->
        <xsl:value-of select="string-join(('EADID', 'Collection Title', 'RefID', 'Box Profile', 'Box Type', 'Box Indicator', 'Folder Indicator', 'Multiple Folders in Same Box?', 'First Object #', 'Last Object #'), $delim) || $break"/>
        <xsl:apply-templates select="//ead2002:*[matches(local-name(), $c)]/ead2002:did/ead2002:container[@type='folder']">
            <xsl:sort select="preceding-sibling::ead2002:container[@id eq current()/@parent]/@type" data-type="text"/>
            <xsl:sort select="preceding-sibling::ead2002:container[@id eq current()/@parent]" data-type="text"/>
        </xsl:apply-templates>
    </xsl:template>
    
    <xsl:template match="ead2002:container[@type='folder']">
        <xsl:variable name="faux-code-of-current-parent-container" select="preceding-sibling::ead2002:container[@id eq current()/@parent]/@type || preceding-sibling::ead2002:container[@id eq current()/@parent]/normalize-space()" as="xs:string"/>
        <xsl:variable name="fingerprint-sum-of-parent-containers" select="(for $x in ../ead2002:container[not(@parent)]
            return number(($x/@type || $x) eq $faux-code-of-current-parent-container)) => sum()"/>
        <!-- could turn this into a function, but just adding it here for now since the file is slightly shorter -->
        <xsl:value-of select="$quote || $EADID || $quote || $delim"/>
        <!-- collection title -->
        <xsl:value-of select="$quote || $EADTitle || $quote || $delim"/>   
        <!-- refid -->
        <xsl:value-of select="$quote || ../../@id || $quote || $delim"/>   
        <!-- container profile -->
        <xsl:value-of select="$quote || preceding-sibling::ead2002:container[@id eq current()/@parent]/@altrender || $quote || $delim"/>
        <!-- box type -->
        <xsl:value-of select="$quote || preceding-sibling::ead2002:container[@id eq current()/@parent]/@type ||$quote || $delim"/>
        <!-- box indicator -->
        <xsl:value-of select="$quote || normalize-space(preceding-sibling::ead2002:container[@id eq current()/@parent]) || $quote || $delim"/>
        <!-- folder indicator -->
        <xsl:value-of select="$quote || normalize-space(.)|| $quote || $delim"/>
        <!-- multiple folders per box boolean -->
        <xsl:value-of select="if ($fingerprint-sum-of-parent-containers gt 1) then 'Multiple Folders Be Here' else 'Nope'"/>
        <!-- leaving 2 empty columns for first and later item/object number, to be filled in during digitization process -->
        <xsl:value-of select="$delim || $delim || $break"/>
    </xsl:template>
    
</xsl:stylesheet>
