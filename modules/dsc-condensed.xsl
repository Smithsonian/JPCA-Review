<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fox="http://xmlgraphics.apache.org/fop/extensions" xmlns:mdc="http://mdc"
    xmlns:ead3="http://ead3.archivists.org/schema/" exclude-result-prefixes="xs ead3 fox mdc"
    version="2.0">

    <!-- this file is imported by "ead3-to-pdf-ua.xsl" -->

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
                <fo:block xsl:use-attribute-sets="h3" id="dsc-contents">
                    <xsl:value-of select="$dsc-title"/>
                </fo:block>

                <!--- START HERE WITH NEW CONDENSED TABLE LAYOUT -->
                <!-- use page breaks?  make our own A-Z groupings??? -->
                <xsl:apply-templates
                    select="ead3:*[matches(local-name(), '^c0|^c1') or local-name() = 'c'][@otherlevel eq 'pagebreak']"
                    mode="#current"/>
                
                <xsl:if test="*[1][@level eq 'recordgrp']">
                    <xsl:call-template name="tableCondensed"/>
                </xsl:if>

                <!-- adding this to grab the last page number-->
                <xsl:if test="$last-page eq 'dsc'">
                    <fo:wrapper id="last-page"/>
                </xsl:if>
            </fo:flow>
        </fo:page-sequence>
    </xsl:template>
    
    <!-- move to functions and named templates -->
    <xsl:template name="tableCondensed">
        <fo:table table-layout="fixed" space-after="12pt" width="100%">
            <fo:table-column column-number="1" column-width="6in"/>
            <fo:table-column column-number="2" column-width="in"/>
            <fo:table-body>
                <xsl:call-template name="tableHeadersCondensed"/>
                <xsl:apply-templates
                    select="ead3:*[matches(local-name(), '^c0|^c1') or local-name() = 'c'][@level eq 'recordgrp']"
                    mode="#current"/>
            </fo:table-body>
        </fo:table>
    </xsl:template>
    
    <!-- move to functions and named templates -->
    <xsl:template name="tableHeadersCondensed">
        <fo:table-row border-bottom="1px dotted #ccc"
            border-top="1pt solid #ccc">
            <fo:table-cell>
                <!-- to do:  move both values to a configuration -->
                <fo:block font-weight="bold" padding="2pt"> Title </fo:block>
            </fo:table-cell>
            <fo:table-cell>
                <!-- useful attribute, if needed:
                    number-columns-spanned="N"
                -->
                <fo:block font-weight="bold" padding="2pt"> Summary </fo:block>
            </fo:table-cell>
        </fo:table-row>
    </xsl:template>

    <!-- recorgrp into table rows -->
    <xsl:template
        match="ead3:*[matches(local-name(), '^c0|^c1') or local-name() = 'c'][@level = ('recordgrp')]"
        mode="condensed">
        <!-- confirm that this works for Sleet, etc. -->
        <xsl:variable name="folder-count" select="count(ead3:*[matches(local-name(), '^c0|^c1') or local-name() = 'c']/ead3:*[matches(local-name(), '^c0|^c1') or local-name() = 'c'][ead3:did/ead3:container[@localtype eq 'folder']])"/>
        <xsl:variable name="folder-text" select="if ($folder-count eq 1) then 'folder' else
            if ($folder-count eq 0) then () else 'folders'"/>
        
        <xsl:variable name="all-rights">
            <xsl:apply-templates select=".//ead3:userestrict[starts-with(ead3:head, 'Rights Statement')]/ead3:p"/>
        </xsl:variable>
        <xsl:variable name="all-warnings">
            <xsl:apply-templates select=".//ead3:scopecontent[starts-with(ead3:head, 'May Contain')]/ead3:p"/>
        </xsl:variable>
        
        <!-- need to de-depupe these! -->
        <xsl:variable name="rights">
            <xsl:copy-of select="$all-rights/*[not(normalize-space() = preceding-sibling::*/normalize-space())]"/>
        </xsl:variable>
        <xsl:variable name="warnings">
            <xsl:copy-of select="$all-warnings/*[not(normalize-space() = preceding-sibling::*/normalize-space())]"/>
        </xsl:variable>
        
        <fo:table-row border-top="1px solid #ccc" margin-top="12pt">
            <fo:table-cell>
                <fo:block margin="4pt 4pt 4pt 0" id="{if (@id) then @id else generate-id(.)}">
                    <xsl:call-template name="combine-identifier-title-and-dates"/>
                </fo:block>
            </fo:table-cell>
            <!-- too many!
            <fo:table-cell>
                <fo:block margin="4pt 0">
                    <xsl:value-of select="distinct-values(.//ead3:physdesc)"/>
                </fo:block>
            </fo:table-cell>
            -->
            <fo:table-cell>
                <!-- or, group the folder counts with the genres? -->
                <fo:block margin="4pt 0">
                    <xsl:value-of select="if ($folder-text) then $folder-count || ' ' || $folder-text else ()"/>
                </fo:block>
            </fo:table-cell>
        </fo:table-row>
        
        <xsl:apply-templates select="$rights/*, $warnings/*" mode="table-row">
            <xsl:with-param name="columns" select="1"/>
        </xsl:apply-templates>

    </xsl:template>
    
    <xsl:template match="*" mode="table-row">
        <xsl:param name="columns"/>
        <fo:table-row keep-with-previous.within-page="always">
            <fo:table-cell>
                <xsl:attribute name="number-columns-spanned" select="$columns"/>
                <fo:block margin="2pt 2pt 2pt 10pt" font-size="9pt">
                    <xsl:apply-templates/>
                </fo:block>
            </fo:table-cell>
        </fo:table-row>
    </xsl:template>

    <xsl:template
        match="ead3:*[matches(local-name(), '^c0|^c1') or local-name() = 'c'][@otherlevel eq 'pagebreak']"
        mode="condensed">
        <fo:block xsl:use-attribute-sets="h4" margin-top="8pt" margin-bottom="8pt" id="{if (@id) then @id else generate-id(.)}">
            <xsl:if test="position() gt 1">
                <xsl:attribute name="break-before" select="'page'"/>
            </xsl:if>
            <xsl:call-template name="combine-identifier-title-and-dates"/>
        </fo:block>
        <xsl:call-template name="tableCondensed"/>
    </xsl:template>

    
</xsl:stylesheet>
