<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fox="http://xmlgraphics.apache.org/fop/extensions"
    xmlns:mdc="http://mdc"
    xmlns:ead3="http://ead3.archivists.org/schema/" exclude-result-prefixes="xs ead3 fox mdc"
    version="2.0">
    
    <!-- this file is imported by "ead3-to-pdf-ua.xsl" -->

    <!-- note, removed recordgrp from the below, for JPCA example -->
    <xsl:param name="dsc-first-c-levels-to-process-before-a-table" select="('series', 'collection', 'fonds')"/>
    <xsl:param name="levels-to-force-a-page-break" select="('series', 'collection', 'fonds')"/>
    <xsl:param name="otherlevels-to-force-a-page-break-and-process-before-a-table" select="('accession', 'acquisition')"/>
    
    <!-- not worrying about multiple DSC sections.  ASpace can only export 1 DSC -->
    <xsl:template match="ead3:dsc" mode="condensed">
        <fo:page-sequence master-reference="contents">
            <!-- Page header -->
            <fo:static-content flow-name="xsl-region-before">
                <xsl:call-template name="header-dsc"/>
            </fo:static-content>
            <!-- Page footer-->
            <fo:static-content flow-name="xsl-region-after" role="artifact">
                <xsl:call-template name="footer"/>
            </fo:static-content>
            <!-- Content of page -->
            <fo:flow flow-name="xsl-region-body">
                <xsl:call-template name="section-start"/>
                <fo:block xsl:use-attribute-sets="h3" id="dsc-contents"><xsl:value-of select="$dsc-title"/></fo:block>
               
                <!--- START HERE WITH NEW CONDENSED TABLE LAYOUT -->
                <!-- use page breaks?  make our own A-Z groupings??? -->
                <xsl:apply-templates select="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c']" mode="#current"/>
                
                <!-- adding this to grab the last page number-->
                <xsl:if test="$last-page eq 'dsc'">
                    <fo:wrapper id="last-page"/>
                </xsl:if>
            </fo:flow>
        </fo:page-sequence>
    </xsl:template>
    
    <!-- change to a table?... or just keep as is, and make sure to add the header inserts, etc? -->
    <xsl:template match="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][@level = ('recordgrp') or @otherlevel = ('pagebreak')]" mode="condensed">
        <xsl:variable name="depth" select="count(ancestor::*) - 3"/> <!-- e.g. c01 = 0, c02 = 1, etc. -->
        <xsl:variable name="cell-margin" select="concat(xs:string($depth * 6), 'pt')"/> <!-- e.g. 0, 8pt for c02, 16pt for c03, etc.-->
        <fo:block margin-top="8pt" margin-bottom="8pt" margin-left="{$cell-margin}" id="{if (@id) then @id else generate-id(.)}">
            <xsl:call-template name="combine-identifier-title-and-dates"/>
            <xsl:apply-templates select="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c']" mode="#current"/>
        </fo:block>
    </xsl:template>
    
    <xsl:template match="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][not(@level = ('recordgrp') or @otherlevel = ('pagebreak'))]" mode="condensed">
        <xsl:apply-templates select="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c']" mode="#current"/>
    </xsl:template>
 
</xsl:stylesheet>
