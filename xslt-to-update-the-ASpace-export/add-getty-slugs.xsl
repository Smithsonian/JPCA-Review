<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ead3="http://ead3.archivists.org/schema/"
    xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:mdc="http://www.local-functions/mdc"
    xmlns:j="http://www.w3.org/2005/xpath-functions"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:array="http://www.w3.org/2005/xpath-functions/array"
    xmlns="http://ead3.archivists.org/schema/"
    exclude-result-prefixes="#all"
    version="3.0">
    
    <xsl:output method="xml" indent="yes" encoding="UTF-8" omit-xml-declaration="no"/>
    
    <xsl:mode on-no-match="shallow-copy"/>
    
    <xsl:param name="release-mode"/>
    <xsl:variable name="rcv-base-uri" select="if ($release-mode eq 'test') then '' else 'https://www.jpcarchive.org/component/'"/>
    
    <!-- first approach. will change this later so that we don't rely on individual API queries..
            ...and then remove it entirely once we have the links stored in ASpace 
    -->    
    <xsl:template match="ead3:c[@level='recordgrp']/ead3:did">
        <xsl:variable name="first-url" select="'https://services.jpcarchive.org/id-management/whatisthis/?ident=' ||
            substring-after(../@id, 'ead3_')"/>
        <xsl:variable name="url-response">
            <xsl:sequence select="unparsed-text($first-url) => json-to-xml()"/>
        </xsl:variable>
        <xsl:variable name="slug-url">
            <xsl:value-of select="$url-response/j:map/j:map[@key='first']/j:array[@key='items']/j:map/j:map[@key='body']/j:string[@key='id'] || '/slug'"/>
        </xsl:variable>
        <xsl:variable name="slug-response">
            <xsl:sequence select="unparsed-text($slug-url) => json-to-xml()"/>
        </xsl:variable>
        <xsl:variable name="rcv-url">
            <xsl:value-of select="$rcv-base-uri || $slug-response/j:map/j:string[@key='content']"/>
        </xsl:variable>
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
            <xsl:if test="$slug-response">
                <dao daotype="derived"
                    href="{$rcv-url}"
                    show="new">
                    <descriptivenote>
                        <p>
                            <xsl:value-of select="ead3:unittitle"/>
                        </p>
                    </descriptivenote>
                </dao>
            </xsl:if>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>