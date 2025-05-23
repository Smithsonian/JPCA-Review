<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fox="http://xmlgraphics.apache.org/fop/extensions"
    xmlns:mdc="http://mdc"
    xmlns:ead3="http://ead3.archivists.org/schema/" exclude-result-prefixes="xs ead3 fox mdc"
    version="2.0">
    
    <!-- this file is imported by "ead3-to-pdf-ua.xsl" -->

    <xsl:param name="dsc-first-c-levels-to-process-before-a-table" select="('series', 'collection', 'fonds')"/>
    <xsl:param name="levels-to-force-a-page-break" select="('series', 'collection', 'fonds')"/>  
    <xsl:param name="otherlevels-to-force-a-page-break-and-process-before-a-table" select="('accession', 'acquisition')"/>
    
    <!-- not worrying about multiple DSC sections.  ASpace can only export 1 DSC -->
    <xsl:template match="ead3:dsc">
        <!-- quick change for JPCA -->
        <xsl:variable name="column-types" select="
            if
            (true()) then 'c-d' (: override all the other options, and just go with a two column table for JPCA? :)
            else if (ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][descendant-or-self::ead3:unitdate or descendant-or-self::ead3:unitdatestructured][descendant-or-self::ead3:container])
            then 'c-d-d'
            else
            if (ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][descendant-or-self::ead3:unitdate or descendant-or-self::ead3:unitdatestructured])
            then 'd-d'
            else
            if (ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][descendant-or-self::ead3:container])
            then 'c-d'
            else 'd'"/>

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
                <xsl:choose>
                    <xsl:when test="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][@level=$dsc-first-c-levels-to-process-before-a-table or @otherlevel=$otherlevels-to-force-a-page-break-and-process-before-a-table]">
                        <xsl:apply-templates select="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c']" mode="dsc-block">
                            <xsl:with-param name="column-types" select="$column-types"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:call-template name="tableBody">
                            <xsl:with-param name="column-types" select="$column-types"/>
                        </xsl:call-template>
                    </xsl:otherwise>
                </xsl:choose>
                <!-- adding this to grab the last page number-->
                <xsl:if test="$last-page eq 'dsc'">
                    <fo:wrapper id="last-page"/>
                </xsl:if>
            </fo:flow>
        </fo:page-sequence>
    </xsl:template>

    <xsl:template match="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c']" mode="dsc-block">
        <xsl:variable name="depth" select="count(ancestor::*) - 3"/> <!-- e.g. c01 = 0, c02 = 1, etc. -->
        <xsl:variable name="cell-margin" select="concat(xs:string($depth * 6), 'pt')"/> <!-- e.g. 0, 8pt for c02, 16pt for c03, etc.-->
        <xsl:variable name="column-types" select="
            if
            (true()) then 'c-d' (: override all the other options, and just go with a two column table for JPCA? :)
            else if (ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][descendant-or-self::ead3:unitdate or descendant-or-self::ead3:unitdatestructured][descendant-or-self::ead3:container])
            then 'c-d-d'
            else
            if (ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][descendant-or-self::ead3:unitdate or descendant-or-self::ead3:unitdatestructured])
            then 'd-d'
            else
            if (ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'][descendant-or-self::ead3:container])
            then 'c-d'
            else 'd'"/>
        <!-- do a second grouping based on the container grouping's primary localtype (i.e. box, volume, reel, etc.)
            then add a custom sort, or just sort those alphabetically -->
        <xsl:variable name="container-groupings">
            <xsl:choose>
                <xsl:when test="ead3:did[ead3:container[2]][not(ead3:container/@parent)]">
                    <xsl:for-each-group select="ead3:did/ead3:container" group-by="lower-case(@localtype)">
                        <container-group component-url="{../../@altrender}" component-title="{substring(../ead3:unittitle[1], 1, 26)}" preceding-box-altrenders='{distinct-values(preceding::ead3:did/ead3:container/@altrender)}' ancestor-access-restrictions='{distinct-values(tokenize(ancestor::ead3:accessrestrict/@localtype, " "))}' series='{ancestor::ead3:c[@level="series" or @otherlevel="accession"][1]/ead3:did/normalize-space(ead3:unitid)}'>
                            <xsl:apply-templates select="current-group()" mode="copy"/>
                        </container-group>
                    </xsl:for-each-group>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each-group select="ead3:did/ead3:container" group-by="mdc:find-the-ultimate-parent-id(.)">
                        <container-group component-url="{../../@altrender}" component-title="{substring(../ead3:unittitle[1], 1, 26)}" preceding-box-altrenders='{distinct-values(preceding::ead3:did/ead3:container/@altrender)}' ancestor-access-restrictions='{distinct-values(tokenize(ancestor::ead3:accessrestrict/@localtype, " "))}' series='{ancestor::ead3:c[@level="series" or @otherlevel="accession"][1]/ead3:did/normalize-space(ead3:unitid)}'>
                            <xsl:apply-templates select="current-group()" mode="copy"/>
                        </container-group>
                    </xsl:for-each-group> 
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="containers-sorted-by-localtype">
            <xsl:for-each-group select="$container-groupings/container-group" group-by="ead3:container[1]/@localtype">
                <xsl:sort select="current-grouping-key()" data-type="text"/>
                <!-- i don't use this element for anything right now, but it could be used, if
                    additional grouping in the presentation was desired -->
                <xsl:element name="{current-grouping-key()}">
                    <xsl:apply-templates select="current-group()" mode="copy">
                        <xsl:sort select="mdc:top-container-to-number(.)"/>
                    </xsl:apply-templates>
                </xsl:element>
            </xsl:for-each-group>
        </xsl:variable>
        <!-- removed keep-with-next.within-page="always" -->
        <fo:block margin-left="{$cell-margin}" id="{if (@id) then @id else generate-id(.)}">
            <xsl:if test="preceding-sibling::ead3:*[@level=$levels-to-force-a-page-break or @otherlevel=$otherlevels-to-force-a-page-break-and-process-before-a-table]">
                <xsl:attribute name="break-before" select="'page'"/>
            </xsl:if>
            <xsl:if test="@audience='internal' and $suppressInternalComponentsInPDF eq false()">
                <xsl:attribute name="border-right-style">solid</xsl:attribute>
                <xsl:attribute name="border-right-width">2px</xsl:attribute>
                <xsl:attribute name="border-right-color">red</xsl:attribute>
            </xsl:if>
            <xsl:choose>
                <xsl:when test="$depth = 0 and (@level = ('series', 'collection', 'recordgrp') or @otherlevel = $otherlevels-to-force-a-page-break-and-process-before-a-table)">
                    <fo:block xsl:use-attribute-sets="h4">
                        <xsl:call-template name="combine-identifier-title-and-dates"/>
                    </fo:block>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:call-template name="dsc-block-identifier-and-title"/>
                </xsl:otherwise>
            </xsl:choose>

            <!-- still need to add the other did elements, and select an order -->
            <xsl:apply-templates select="ead3:did" mode="dsc"/>
            <xsl:apply-templates select="ead3:bioghist, ead3:scopecontent
                , ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                , ead3:originalsloc, ead3:otherfindaid, ead3:phystech, ead3:fileplan, ead3:odd, ead3:bibliography, ead3:arrangement, ead3:controlaccess" mode="dsc"/>
            <!-- still need to add templates here for digital objects.  anything else?  -->
            <xsl:call-template name="container-layout">
                <xsl:with-param name="containers-sorted-by-localtype" select="$containers-sorted-by-localtype"/>
            </xsl:call-template>
        </fo:block>
        <xsl:choose>
            <xsl:when test="not(ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'])"/>
            <xsl:otherwise>
               <xsl:call-template name="tableBody">
                   <xsl:with-param name="column-types" select="$column-types"/>
               </xsl:call-template>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c']" mode="dsc-table">
        <xsl:param name="first-row" select="if (position() eq 1 and (
                parent::ead3:dsc
                or parent::*[@level=$dsc-first-c-levels-to-process-before-a-table]
                or parent::*[@otherlevel=$otherlevels-to-force-a-page-break-and-process-before-a-table])
            )
            then true() else false()"/>
        <xsl:param name="no-children" select="if (not(ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c'])) then true() else false()"/>
        <xsl:param name="last-row" select="if (position() eq last() and $no-children) then true() else false()"/>
        <xsl:param name="depth"/> <!-- e.g. c01 = 0, c02 = 1, etc. -->
        <xsl:param name="column-types"/>
        <xsl:variable name="cell-margin" select="concat(xs:string($depth * 8), 'pt')"/> <!-- e.g. 0, 8pt for c02, 16pt for c03, etc.-->
        <!-- should change this so that we don't repeat the definition of this variable, but oh well -->
        <xsl:variable name="container-groupings">
            <xsl:choose>
                <xsl:when test="ead3:did[ead3:container[2]][not(ead3:container/@parent)]">
                    <xsl:for-each-group select="ead3:did/ead3:container" group-by="lower-case(@localtype)">
                        <container-group component-url="{../../@altrender}" component-title="{substring(../ead3:unittitle[1], 1, 26)}" preceding-box-altrenders='{distinct-values(preceding::ead3:did/ead3:container/@altrender)}' ancestor-access-restrictions='{distinct-values(tokenize(ancestor::ead3:accessrestrict/@localtype, " "))}' series='{ancestor::ead3:c[@level="series" or @otherlevel="accession"][1]/ead3:did/normalize-space(ead3:unitid)}'>
                            <xsl:apply-templates select="current-group()" mode="copy"/>
                        </container-group>
                    </xsl:for-each-group>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:for-each-group select="ead3:did/ead3:container" group-by="mdc:find-the-ultimate-parent-id(.)">
                        <container-group component-url="{../../@altrender}" component-title="{substring(../ead3:unittitle[1], 1, 26)}" preceding-box-altrenders='{distinct-values(preceding::ead3:did/ead3:container/@altrender)}' ancestor-access-restrictions='{distinct-values(tokenize(ancestor::ead3:accessrestrict/@localtype, " "))}' series='{ancestor::ead3:c[@level="series" or @otherlevel="accession"][1]/ead3:did/normalize-space(ead3:unitid)}'>
                            <xsl:apply-templates select="current-group()" mode="copy"/>
                        </container-group>
                    </xsl:for-each-group> 
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="containers-sorted-by-localtype">
            <xsl:for-each-group select="$container-groupings/container-group" group-by="ead3:container[1]/@localtype">
                <xsl:sort select="current-grouping-key()" data-type="text"/>
                <xsl:element name="{current-grouping-key()}">
                    <xsl:apply-templates select="current-group()" mode="copy">
                        <xsl:sort select="mdc:top-container-to-number(.)"/>
                    </xsl:apply-templates>
                </xsl:element>
            </xsl:for-each-group>
        </xsl:variable>
        <!--  need to do something here to fix rows that have REALLY long notes. see 15.pdf -->
        <fo:table-row>
            <xsl:if test="@otherlevel eq 'pagebreak' and position() gt 1">
                <xsl:attribute name="break-before" select="'page'"/>
            </xsl:if>
            <xsl:call-template name="dsc-table-row-border">
                <xsl:with-param name="last-row" select="$last-row"/>
                <xsl:with-param name="no-children" select="$no-children"/>
                <xsl:with-param name="audience" select="@audience"/>
                <xsl:with-param name="component-string-length" select="sum(for $x in child::*[not(local-name()='c')] return string-length($x))"/>
            </xsl:call-template>
            <xsl:choose>
                <xsl:when test="$column-types eq 'c-d-d'">
                    <fo:table-cell xsl:use-attribute-sets="dsc-table-cells">
                        <xsl:call-template name="container-layout">
                            <xsl:with-param name="containers-sorted-by-localtype" select="$containers-sorted-by-localtype"/>
                        </xsl:call-template>
                    </fo:table-cell>
                    <fo:table-cell xsl:use-attribute-sets="dsc-table-cells">
                        <fo:block>
                            <xsl:choose>
                                <xsl:when test="$first-row eq true()">
                                    <fo:marker marker-class-name="continued-text"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <fo:marker marker-class-name="continued-text">
                                        <fo:inline>
                                            <xsl:call-template name="ancestor-info"/>
                                        </fo:inline>
                                    </fo:marker>
                                </xsl:otherwise>
                            </xsl:choose>
                        </fo:block>
                        <!-- do the title and/or date stuff here -->
                        <fo:block-container margin-left="{$cell-margin}" id="{if (@id) then @id else generate-id(.)}">
                            <fo:block-container>
                                <fo:block>
                                    <xsl:call-template name="dsc-block-identifier-and-title"/>
                                </fo:block>
                                <!-- still need to add the other did elements, and select an order -->
                                <fo:block>
                                    <xsl:apply-templates select="ead3:did" mode="dsc"/>
                                </fo:block>
                            </fo:block-container>
                            <fo:block-container>
                                <fo:block>
                                    <xsl:apply-templates select="ead3:bioghist, ead3:scopecontent
                                        , ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                                        , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                                        , ead3:originalsloc, ead3:otherfindaid, ead3:phystech, ead3:fileplan, ead3:odd, ead3:bibliography, ead3:arrangement, ead3:controlaccess" mode="dsc"/>
                                </fo:block>
                            </fo:block-container>
                        </fo:block-container>
                    </fo:table-cell>
                    <fo:table-cell xsl:use-attribute-sets="dsc-table-cells">
                        <fo:block>
                            <xsl:apply-templates select="ead3:did/ead3:unitdatestructured | ead3:did/ead3:unitdate" mode="dsc"/>
                        </fo:block>
                    </fo:table-cell>
                </xsl:when>
                <xsl:when test="$column-types eq 'd-d'">
                    <fo:table-cell xsl:use-attribute-sets="dsc-table-cells">
                        <fo:block>
                            <xsl:choose>
                                <xsl:when test="$first-row eq true()">
                                    <fo:marker marker-class-name="continued-text"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <fo:marker marker-class-name="continued-text">
                                        <fo:inline>
                                            <xsl:call-template name="ancestor-info"/>
                                        </fo:inline>
                                    </fo:marker>
                                </xsl:otherwise>
                            </xsl:choose>
                        </fo:block>
                        <!-- do the title and/or date stuff here -->
                        <fo:block-container margin-left="{$cell-margin}" id="{if (@id) then @id else generate-id(.)}">
                            <fo:block-container>
                                <fo:block>
                                    <xsl:call-template name="dsc-block-identifier-and-title"/>
                                </fo:block>
                                <!-- still need to add the other did elements, and select an order -->
                                <fo:block>
                                    <xsl:apply-templates select="ead3:did" mode="dsc"/>
                                </fo:block>
                            </fo:block-container>
                            <fo:block-container>
                                <fo:block>
                                    <xsl:apply-templates select="ead3:bioghist, ead3:scopecontent
                                        , ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                                        , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                                        , ead3:originalsloc, ead3:otherfindaid, ead3:phystech, ead3:fileplan, ead3:odd, ead3:bibliography, ead3:arrangement, ead3:controlaccess" mode="dsc"/>
                                </fo:block>
                            </fo:block-container>
                        </fo:block-container>
                    </fo:table-cell>
                    <fo:table-cell xsl:use-attribute-sets="dsc-table-cells">
                        <fo:block>
                            <xsl:apply-templates select="ead3:did/ead3:unitdatestructured | ead3:did/ead3:unitdate" mode="dsc"/>
                        </fo:block>
                    </fo:table-cell>
                </xsl:when>
                <xsl:when test="$column-types eq 'c-d'">
                    <fo:table-cell xsl:use-attribute-sets="dsc-table-cells">
                        <xsl:call-template name="container-layout">
                            <xsl:with-param name="containers-sorted-by-localtype" select="$containers-sorted-by-localtype"/>
                        </xsl:call-template>
                    </fo:table-cell>
                    <fo:table-cell xsl:use-attribute-sets="dsc-table-cells">
                        <fo:block>
                            <xsl:choose>
                                <xsl:when test="$first-row eq true()">
                                    <fo:marker marker-class-name="continued-text"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <fo:marker marker-class-name="continued-text">
                                        <fo:inline>
                                            <xsl:call-template name="ancestor-info"/>
                                        </fo:inline>
                                    </fo:marker>
                                </xsl:otherwise>
                            </xsl:choose>
                        </fo:block>
                        <!-- do the title and/or date stuff here -->
                        <fo:block-container margin-left="{$cell-margin}" id="{if (@id) then @id else generate-id(.)}">
                            <fo:block-container>
                                <fo:block xsl:use-attribute-sets="margin-after-tiny">
                                    <xsl:call-template name="combine-identifier-title-and-dates"/>
                                </fo:block>
                                <!-- still need to add the other did elements, and select an order -->
                                <fo:block>
                                    <xsl:apply-templates select="ead3:did" mode="dsc"/>
                                </fo:block>
                            </fo:block-container>
                            <fo:block-container>
                                <fo:block>
                                    <xsl:apply-templates select="ead3:bioghist, ead3:scopecontent
                                        , ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                                        , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                                        , ead3:originalsloc, ead3:otherfindaid, ead3:phystech, ead3:fileplan, ead3:odd, ead3:bibliography, ead3:arrangement, ead3:controlaccess" mode="dsc"/>
                                </fo:block>
                            </fo:block-container>
                        </fo:block-container>
                    </fo:table-cell>
                </xsl:when>
                <xsl:otherwise>
                    <fo:table-cell xsl:use-attribute-sets="dsc-table-cells">
                        <fo:block>
                            <xsl:choose>
                                <xsl:when test="$first-row eq true()">
                                    <fo:marker marker-class-name="continued-text"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <fo:marker marker-class-name="continued-text">
                                        <fo:inline>
                                            <xsl:call-template name="ancestor-info"/>
                                        </fo:inline>
                                    </fo:marker>
                                </xsl:otherwise>
                            </xsl:choose>
                        </fo:block>
                        <!-- do the title and/or date stuff here -->
                        <fo:block-container margin-left="{$cell-margin}" id="{if (@id) then @id else generate-id(.)}">
                            <fo:block-container>
                                <fo:block xsl:use-attribute-sets="margin-after-tiny">
                                    <xsl:call-template name="combine-identifier-title-and-dates"/>
                                </fo:block>
                                <!-- still need to add the other did elements, and select an order -->
                                <fo:block>
                                    <xsl:apply-templates select="ead3:did" mode="dsc"/>
                                </fo:block>
                            </fo:block-container>
                            <fo:block-container>
                                <fo:block>
                                    <xsl:apply-templates select="ead3:bioghist, ead3:scopecontent
                                        , ead3:acqinfo, ead3:custodhist, ead3:accessrestrict, ead3:userestrict, ead3:prefercite
                                        , ead3:processinfo, ead3:altformavail, ead3:relatedmaterial, ead3:separatedmaterial, ead3:accruals, ead3:appraisals
                                        , ead3:originalsloc, ead3:otherfindaid, ead3:phystech, ead3:fileplan, ead3:odd, ead3:bibliography, ead3:arrangement, ead3:controlaccess" mode="dsc"/>
                                </fo:block>
                            </fo:block-container>
                        </fo:block-container>
                    </fo:table-cell>
                </xsl:otherwise>
            </xsl:choose>
        </fo:table-row>
        <xsl:apply-templates select="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c']" mode="dsc-table">
            <xsl:with-param name="depth" select="$depth + 1"/>
            <xsl:with-param name="column-types" select="$column-types"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="ead3:did" mode="dsc">
        <xsl:apply-templates select="ead3:abstract, ead3:physdescstructured, ead3:physdesc,
            ead3:physdescset, ead3:physloc,
            ead3:langmaterial, ead3:materialspec, ead3:origination, ead3:repository, ead3:dao, ead3:daoset/ead3:dao" mode="#current"/>
    </xsl:template>

    <xsl:template match="ead3:container">
        <!-- Remember:  we've added a "container-grouping" element as the parent
        e.g. *:box/*container-grouping/ead3:container-->
        
        <xsl:variable name="container-lower-case" select="lower-case(@localtype)"/>
   
        <xsl:call-template name="get-container-prefix-info">
            <xsl:with-param name="container-lower-case" select="$container-lower-case"/>
        </xsl:call-template>
        
        <!-- and here's where we print out the actual container indicator... and since barcodes could extend the margin without having a space for a newline, we'll make those smaller, at 7pt. -->
        <xsl:choose>
            <xsl:when test="$container-lower-case eq 'item_barcode'">
                <fo:inline font-size="7pt">
                    <xsl:apply-templates/>
                </fo:inline>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>

        <!-- comma separator or no? -->
        <xsl:if test="position() ne last()">
            <xsl:text>, </xsl:text>
        </xsl:if>
        
    </xsl:template>

    <xsl:template match="ead3:container" mode="collapse-containers">
        <xsl:param name="first-container-in-range" select="."/>
        <xsl:variable name="current-container" select="."/>
        <xsl:variable name="next-container" select="following-sibling::ead3:container[1]"/>
        
        <xsl:choose>
            <!-- e.g. end of the line, regardless of ranges (but still might need to output a range) -->
            <xsl:when test="not(following-sibling::ead3:container)">
                    <xsl:value-of select="if ($first-container-in-range eq $current-container)
                        then $current-container
                        else concat($first-container-in-range, '&#x2013;', $current-container)"/>
            </xsl:when>
            <!-- e.g. 6, 6a, 6b, 6c, 7 (could also handle a rule here to condense 6a-6c)
      perhaps: when has a remainder plus floor of current = floor of next. -->
            <xsl:when test="mdc:top-container-to-number($current-container) mod 1 gt 0
                and mdc:top-container-to-number($next-container) mod 1 gt 0
                and (floor(mdc:top-container-to-number($current-container)) eq floor(mdc:top-container-to-number($next-container)))">
                <xsl:apply-templates select="$next-container" mode="#current">
                    <xsl:with-param name="first-container-in-range" select="$first-container-in-range"/>
                    <xsl:with-param name="current-container" select="$next-container"/>
                </xsl:apply-templates>
            </xsl:when>
            <!-- e.g. 1, 2, 3, 4, 5, 6, 8
        when we're at 1 -5, we just want to keep going.
      -->
            <xsl:when test="mdc:top-container-to-number($current-container) + 1 eq mdc:top-container-to-number($next-container)">
                <xsl:apply-templates select="$next-container" mode="#current">
                    <xsl:with-param name="first-container-in-range" select="$first-container-in-range"/>
                    <xsl:with-param name="current-container" select="$next-container"/>
                </xsl:apply-templates>
            </xsl:when>
            <!-- e.g. in the above example, let's say we get to 6.
      -->
            <xsl:when test="mdc:top-container-to-number($current-container) + 1 ne mdc:top-container-to-number($next-container)">
                <xsl:value-of select="if ($first-container-in-range eq $current-container)
                        then $current-container
                        else concat($first-container-in-range, '&#x2013;', $current-container)"/>
                <xsl:if test="following-sibling::ead3:container">
                    <!-- should paramertize the separator, but this is fine for now -->
                    <xsl:text>, </xsl:text>
                    <xsl:apply-templates select="$next-container" mode="#current">
                        <xsl:with-param name="first-container-in-range" select="$next-container"/>
                        <xsl:with-param name="current-container" select="$next-container"/>
                    </xsl:apply-templates>
                </xsl:if>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>
