<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fox="http://xmlgraphics.apache.org/fop/extensions"
    xmlns:ead3="http://ead3.archivists.org/schema/" exclude-result-prefixes="xs ead3"
    version="2.0">

    <xsl:output method="xml" encoding="UTF-8"/>
    <!-- adding this to fix a spacing issue in the overview section.  not sure if this should be needed in all cases, but keep an eye out on it -->
    <xsl:strip-space elements="ead3:unitdatestructured ead3:languageset"/>

    <xsl:include href="modules/embedded-metadata.xsl"/>
    <xsl:include href="modules/attributes.xsl"/>
    <xsl:include href="modules/bookmarks.xsl"/>
    <xsl:include href="modules/common-block-and-inline-elements.xsl"/>
    <xsl:include href="modules/functions-and-named-templates.xsl"/>

    <xsl:include href="modules/cover-page.xsl"/>
    <xsl:include href="modules/table-of-contents.xsl"/>

    <xsl:include href="modules/archdesc.xsl"/>
    <xsl:import href="modules/dsc.xsl"/>
    <xsl:import href="modules/dsc-condensed.xsl"/>
    <xsl:include href="modules/odd-index.xsl"/>
    <xsl:include href="modules/index.xsl"/>
    <xsl:include href="modules/controlaccess.xsl"/>
    
    <xsl:include href="modules/relators.xsl"/>
    
    <xsl:key name="relator-code" match="relator" use="code"/>


    <!--======== Requirements ========-->
    <!--
            >= Apache FOP 2.1

    for instructions on how to turn on the built-in accessibility features in FOP, see:

    https://xmlgraphics.apache.org/fop/2.10/accessibility.html
    
    -->
    <!--======== End: Requirements ========-->

    <!-- global parameters -->
    
    <xsl:param name="pdf-version" select="'regular'" as="xs:string"/>
    
    <xsl:param name="primary-language-of-finding-aid" select="'en'"/>
    <xsl:param name="primary-font-for-pdf" select="'Open_Sans'"/>
    <xsl:param name="serif-font" select="'CH-H'"/>
    <xsl:param name="sans-serif-font" select="'Open_Sans'"/>
    <xsl:param name="backup-fonts" select="('KurintoText', 'NotoNaskhArabic', 'SourceHanSerifSC', 'SourceHanSerifTC', 'SourceHanSerifJ', 'SourceHanSerifK', 'ArialUnicode')"/>
    <xsl:param name="default-font-size" select="'10pt'"/>
    <!-- will pass false() when using this process to do staff-only PDF previews -->
    <xsl:param name="suppressInternalComponentsInPDF" select="true()" as="xs:boolean"/>
    <xsl:param name="start-page-1-after-table-of-contents" select="false()"/>
    <!-- if you change this to true, you'll lose the markers (e.g. series N continued)
    since those are currently in the table header, not the page headers.
    -->
    <xsl:param name="dsc-omit-table-header-at-break" select="false()"/>
    <xsl:param name="include-paging-info" select="false()"/>
    <xsl:param name="paging-info-title" select="'Requesting Instructions'"/>
    
    <!-- should make this a function since we might want to paramertize the abbreviations, but hard coding it for now -->
    <xsl:variable name="container-localtypes" select="distinct-values(ead3:ead/ead3:archdesc/ead3:dsc//ead3:container/@localtype)"/>
    <xsl:variable name="include-container-key" select="if ($container-localtypes = ('box', 'folder', 'volume', 'item_barcode')) then true() else false()"/>

    <xsl:param name="archdesc-did-title" select="'Collection Overview'"/>
    <xsl:param name="admin-info-title" select="'Administrative Information'"/>
    <xsl:param name="dsc-title" select="'Collection Contents'"/>
    <xsl:param name="control-access-title" select="'Selected Search Terms'"/>
    <xsl:param name="control-access-context-note">
        <xsl:text>The following terms have been used to index the description of this collection. They are grouped by name of person or organization, by subject or location, and by occupation and listed alphabetically therein.</xsl:text>
    </xsl:param>
    <xsl:param name="control-access-origination-grouping-title" select="'Contributors'"/>
    <xsl:param name="control-access-origination-sources-grouping-title" select="'Acquired From'"/>
    <xsl:param name="resource-unpublished-note" select="'*** UNPUBLISHED DRAFT ***'"/>
    <xsl:param name="sub-resource-unpublished-note" select="'Includes unpublished notes and/or components'"/>

    <xsl:param name="odd-headings-to-add-at-end" select="'index|appendix'"/>
    <!-- toc and bookmarks used to be the same...  trying something different now, but update this approach once it's figured out -->
    <xsl:param name="levels-to-include-in-toc" select="('series', 'subseries', 'collection', 'fonds')"/>
    <xsl:param name="otherlevels-to-include-in-toc" select="('accession', 'acquisition', 'pagebreak')"/>
    <xsl:param name="levels-to-include-in-bookmarks" select="('series', 'subseries', 'collection', 'fonds', 'recordgrp', 'subgrp')"/>
    <xsl:param name="otherlevels-to-include-in-bookmarks" select="('accession', 'acquisition', 'pagebreak')"/>
    
    <xsl:param name="logo-location" select="''" as="xs:string"/>
    
    <xsl:param name="bulk-date-prefix-text" select="'bulk '" as="xs:string"/>
    
    <!-- document-based variables -->
    <xsl:variable name="unpublished-draft" select="if ($suppressInternalComponentsInPDF eq false() and (ead3:ead/@audience='internal' or ead3:ead/ead3:archdesc/@audience='internal')) then true() else false()"/>
    <xsl:variable name="unpublished-subelements" select="if ($suppressInternalComponentsInPDF eq false() and (ead3:ead/*/*//@audience='internal')) then true() else false()"/>
    <xsl:variable name="finding-aid-title" select="ead3:ead/ead3:control/ead3:filedesc/ead3:titlestmt/ead3:titleproper[not(@localtype = 'filing')][1]"/>
    <xsl:variable name="finding-aid-author" select="ead3:ead/ead3:control/ead3:filedesc/ead3:titlestmt/ead3:author"/>
    <xsl:variable name="finding-aid-summary"
        select="
            if (ead3:ead/ead3:archdesc/ead3:did/ead3:abstract[1])
            then
                ead3:ead/ead3:archdesc/ead3:did/ead3:abstract[1]
            else
                ead3:ead/ead3:archdesc/ead3:scopecontent[1]/ead3:p[1]"/>
    <!--example: <recordid instanceurl="http://hdl.handle.net/10079/fa/beinecke.ndy10">beinecke.ndy10</recordid> -->
    <xsl:variable name="finding-aid-identifier" select="ead3:ead/ead3:control/ead3:recordid[1]"/>
    
    <xsl:variable name="JPCA-instance" select="'staging'"/>
    <xsl:variable name="JPCA-base-uri" select="if ($JPCA-instance eq 'staging') then 'https://staging-www.jpcarchive.org/' else 'https://www.jpcarchive.org/'"/>
    <!-- udpdate finding aid identifier with RCV Slug, once gathered -->
    <xsl:variable name="online-link" select="if ($finding-aid-identifier/@instanceurl/normalize-space()) then $finding-aid-identifier/@instanceurl/normalize-space()
        else concat($JPCA-base-uri, normalize-space($finding-aid-identifier))"/>
    <xsl:variable name="online-link-prefatory-text" select="'To cite or bookmark this finding aid, please use the following link: '"/>
    <xsl:variable name="holding-repository" select="ead3:ead/ead3:archdesc/ead3:did/ead3:repository[1]"/>
    <xsl:variable name="resource-url" select="ead3:ead/ead3:archdesc/@altrender"/>
    <!-- do i need a variable for the repository code, or can we trust that the repository names won't be edited in ASpace?
    probably shouldn't trust that... so....-->
    <xsl:variable name="repository-code" select="ead3:ead/ead3:control/ead3:recordid[1]/substring-before(., '.')"/>
    <xsl:variable name="collection-title" select="ead3:ead/ead3:archdesc/ead3:did/ead3:unittitle[1]"/>
    <xsl:variable name="collection-identifier" select="ead3:ead/ead3:archdesc/ead3:did/ead3:unitid[not(@audience = 'internal')][1]"/>
    <!-- last page options are controlacces, odd/head contains index, index, dsc, archdesc -->
    <xsl:variable name="last-page" select="if (ead3:ead/ead3:archdesc/ead3:controlaccess) then 'controlaccess'
        else if (ead3:ead/ead3:archdesc/ead3:odd[matches(lower-case(normalize-space(ead3:head)), $odd-headings-to-add-at-end)]) then 'odd-index'
        else if (ead3:ead/ead3:archdesc/ead3:index) then 'index'
        else if (ead3:ead/ead3:archdesc/ead3:dsc[*]) then 'dsc'
        else 'archdesc'"/>

    <!--========== PAGE SETUP =======-->
    <xsl:template match="/">
        <fo:root xml:lang="{$primary-language-of-finding-aid}" font-family="{string-join(($primary-font-for-pdf, $backup-fonts), ',')}" font-size="{$default-font-size}">
            <fo:layout-master-set>
                <xsl:call-template name="define-page-masters"/>
                <xsl:call-template name="define-page-sequences"/>
            </fo:layout-master-set>
            <!-- Adds embedded metadata, which is required for the title, at least, to ensure compatibility with the PDF-UA standard  -->
            <xsl:call-template name="embed-metadata"/>
            <!-- Builds PDF bookmarks  -->
            <xsl:apply-templates select="ead3:ead/ead3:archdesc" mode="bookmarks"/>
            <!-- see cover-page.xsl -->
            <xsl:apply-templates select="ead3:ead/ead3:control"/>
            
            <!-- see table-of-contents.xsl -->
            <xsl:apply-templates select="ead3:ead/ead3:archdesc" mode="toc"/>                
        
            <!-- see archdesc.xsl -->
            <xsl:apply-templates select="ead3:ead/ead3:archdesc[*]"/>
            
            <!-- see dsc.xsl -->
            <xsl:choose>
                <xsl:when test="$pdf-version eq 'regular'">
                    <xsl:apply-templates select="ead3:ead/ead3:archdesc/ead3:dsc[*]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:apply-templates select="ead3:ead/ead3:archdesc/ead3:dsc" mode="condensed"/>
                </xsl:otherwise>
            </xsl:choose>


            <!-- see odd-index.xsl -->
            <xsl:apply-templates select="ead3:ead/ead3:archdesc/ead3:odd[matches(lower-case(normalize-space(ead3:head)), $odd-headings-to-add-at-end)][1]"/>
            <!-- see index.xsl -->
            <xsl:apply-templates select="ead3:ead/ead3:archdesc/ead3:index[1]"/>

            <!-- see controlaccess.xsl -->
            <xsl:apply-templates select="ead3:ead/ead3:archdesc[ead3:controlaccess/*]" mode="control-access-section"/>
        </fo:root>
    </xsl:template>

    <xsl:template name="define-page-masters">
        <!-- Page master for Cover Page -->
        <fo:simple-page-master master-name="cover" page-height="11in" page-width="8.5in" margin="0.4in">
            <fo:region-body margin="1.5in 0.3in 0.3in 0.3in"/>
            <fo:region-before extent="1.5in"/>
            <fo:region-after extent="0.3in"/>
            <fo:region-start extent="0.3in"/>
            <fo:region-end extent="0.3in"/>
        </fo:simple-page-master>
        <!-- Page master for Table of Contents -->
        <fo:simple-page-master master-name="table-of-contents" page-height="11in" page-width="8.5in" margin="0.4in">
            <fo:region-body margin="0.5in 0.3in 0.3in 0.3in"/>
            <fo:region-before extent="0.5in"/>
            <fo:region-after extent="0.3in"/>
            <fo:region-start extent="0.3in"/>
            <fo:region-end extent="0.3in"/>
        </fo:simple-page-master>
        <!-- Page master for Archdesc -->
        <fo:simple-page-master master-name="archdesc" page-height="11in" page-width="8.5in" margin="0.4in">
            <fo:region-body margin="0.5in 0.3in 0.3in 0.3in"/>
            <fo:region-before extent="0.5in"/>
            <fo:region-after extent="0.3in"/>
            <fo:region-start extent="0.3in"/>
            <fo:region-end extent="0.3in"/>
        </fo:simple-page-master>
        <!-- Page master for DSC -->
        <fo:simple-page-master master-name="contents" page-height="11in" page-width="8.5in" margin="0.4in">
            <fo:region-body margin="0.5in 0.3in 0.3in 0.3in"/>
            <fo:region-before extent="0.5in"/>
            <fo:region-after extent="0.3in"/>
            <fo:region-start extent="0.3in"/>
            <fo:region-end extent="0.3in"/>
        </fo:simple-page-master>
        <!-- Page master for Index -->
        <fo:simple-page-master master-name="index" page-height="11in" page-width="8.5in" margin="0.4in">
            <fo:region-body margin="0.5in 0.3in 0.3in 0.3in"/>
            <fo:region-before extent="0.5in"/>
            <fo:region-after extent="0.3in"/>
            <fo:region-start extent="0.3in"/>
            <fo:region-end extent="0.3in"/>
        </fo:simple-page-master>
        <!-- Page master for Control Accession -->
        <fo:simple-page-master master-name="control-access" page-height="11in" page-width="8.5in" margin="0.4in">
            <fo:region-body column-count="2" column-gap=".5in" margin="0.5in 0.3in 0.3in 0.3in"/>
            <fo:region-before extent="0.5in"/>
            <fo:region-after extent="0.3in"/>
            <fo:region-start extent="0.3in"/>
            <fo:region-end extent="0.3in"/>
        </fo:simple-page-master>
    </xsl:template>

    <xsl:template name="define-page-sequences">
        <!-- any reason (or design choice) to specify recto and verso??? -->
        <fo:page-sequence-master master-name="cover-sequence">
            <fo:single-page-master-reference master-reference="cover"/>
        </fo:page-sequence-master>
        <fo:page-sequence-master master-name="toc-sequence">
            <fo:repeatable-page-master-reference master-reference="table-of-contents"/>
        </fo:page-sequence-master>
        <fo:page-sequence-master master-name="archdesc-sequence">
            <fo:repeatable-page-master-reference master-reference="archdesc"/>
        </fo:page-sequence-master>
        <fo:page-sequence-master master-name="dsc-sequence">
            <fo:repeatable-page-master-reference master-reference="contents"/>
        </fo:page-sequence-master>
        <fo:page-sequence-master master-name="odd-index-sequence">
            <fo:repeatable-page-master-reference master-reference="index"/>
        </fo:page-sequence-master>
        <fo:page-sequence-master master-name="index-sequence">
            <fo:repeatable-page-master-reference master-reference="index"/>
        </fo:page-sequence-master>
        <fo:page-sequence-master master-name="ca-sequence">
            <fo:repeatable-page-master-reference master-reference="control-access"/>
        </fo:page-sequence-master>
        <!-- whatever else that's required for access headings, end-of-file indices, etc. -->
    </xsl:template>
    <!--========== END: PAGE SETUP =======-->
</xsl:stylesheet>
