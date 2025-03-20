<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fox="http://xmlgraphics.apache.org/fop/extensions"
    xmlns:ead3="http://ead3.archivists.org/schema/" exclude-result-prefixes="xs ead3 fox"
    version="2.0">

    <!-- this file is imported by "ead3-to-pdf-ua.xsl" -->

    <!--========== Cover Page ========-->
    <xsl:template match="ead3:control">
        <fo:page-sequence master-reference="cover" xsl:use-attribute-sets="center-text">
            <fo:static-content flow-name="xsl-region-before">
                <fo:block id="cover-page">
                    <xsl:apply-templates select="$holding-repository"/>
                    <!-- Or, 
                    <xsl:text>Johnson Publishing Company Archive</xsl:text>
                    with parmertized text instead.
                    -->
                </fo:block>
            </fo:static-content>
            <fo:static-content flow-name="xsl-region-after">
                <fo:block>
                    <xsl:apply-templates select="ead3:maintenancehistory[1]/ead3:maintenanceevent[1]/ead3:eventdatetime[1]" mode="titlepage.pdf.creation.date"/>
                </fo:block>
            </fo:static-content>
            <fo:flow flow-name="xsl-region-body">
                <xsl:if test="$unpublished-draft eq true()">
                    <fo:block xsl:use-attribute-sets="unpublished">
                        <xsl:value-of select="$resource-unpublished-note"/>
                    </fo:block>
                </xsl:if>
                <fo:block xsl:use-attribute-sets="h1">
                    <xsl:apply-templates select="$finding-aid-title"/>
                </fo:block>
                <xsl:if test="$unpublished-subelements">
                    <fo:block xsl:use-attribute-sets="unpublished">
                        <xsl:value-of select="$sub-resource-unpublished-note"/>
                    </fo:block>
                </xsl:if>
                <fo:block xsl:use-attribute-sets="h2 margin-after-large">
                    <xsl:apply-templates select="$collection-identifier"/>
                </fo:block>
                <xsl:call-template name="coverpage.image"/>
                <!--
                <fo:block xsl:use-attribute-sets="margin-after-small">
                    <xsl:apply-templates select="$finding-aid-author"/>
                </fo:block>
                -->
                <fo:block xsl:use-attribute-sets="margin-after-small">
                    <xsl:apply-templates select="ead3:filedesc/ead3:publicationstmt[1]/ead3:date[1]"/>
                </fo:block>
                <fo:block>
                    <xsl:apply-templates select="ead3:filedesc/ead3:publicationstmt[1]/ead3:address[1]"/>
                </fo:block>
            </fo:flow>
        </fo:page-sequence>
    </xsl:template>
    <!--========== End: Cover Page ======== -->

    <xsl:template name="coverpage.image">
        <!-- update this section once we get finalized images.
            the current PNG is just a screen capture from a PDF file. -->
        <fo:block xsl:use-attribute-sets="margin-after-large">
            <xsl:variable name="image" select="concat($logo-location, 'config/logos/G_J_N_h.png')"/>
            <fo:external-graphic src="url({$image})"
                width="100%"
                content-height="100%"
                content-width="scale-to-fit"
                scaling="uniform"
                fox:alt-text="Three graphical logos representing the Getty Institution, the Johnson Publishing Company Archive, and the National Museum of African American History and Culture, Smithsonian Institution."/>
        </fo:block>
    </xsl:template>

    <xsl:template match="ead3:addressline">
        <fo:block>
            <xsl:apply-templates/>
        </fo:block>
    </xsl:template>

    <xsl:template match="ead3:eventdatetime" mode="titlepage.pdf.creation.date">        
        <!-- if kept like this, we'll need paramertize the time zone
        if no parameter is passed, it should still be able to get the time zone, but not sure about the timezone
        if the server becomes hosted, etc., so i'm passing the value for now.
        -->
        <xsl:variable name="adjustedDateTime" select="adjust-dateTime-to-timezone(xs:dateTime(.), xs:dayTimeDuration('-PT5H0M'))"/>
        
        <fo:block font-size="9pt">
            <xsl:text>Last exported at </xsl:text>
            <xsl:value-of select="format-dateTime($adjustedDateTime, '[h]:[m01] [Pn] ET, on [FNn], [MNn] [D1o], [Y0001]')"/>
        </fo:block>
    </xsl:template>



</xsl:stylesheet>
