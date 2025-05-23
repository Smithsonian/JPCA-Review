<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fo="http://www.w3.org/1999/XSL/Format"
    xmlns:fox="http://xmlgraphics.apache.org/fop/extensions"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:mdc="http://mdc"
    xmlns:ead3="http://ead3.archivists.org/schema/" 
    exclude-result-prefixes="xs math mdc fox"
    version="3.0">
    
    <xsl:param name="unitid-trailing-punctuation" select="':'"/>
    <xsl:variable name="unitid-separator" select="concat($unitid-trailing-punctuation, ' ')"/>
    
    <!-- also need to make sure that the top-level dates display if those are NOT normalized
        -->
    <!-- just used for the unittitle + dao/descriptivenote/p deep-equal tests -->
    <xsl:function name="mdc:extract-text-no-spaces" as="xs:string">
        <xsl:param name="input" as="node()"/>
        <xsl:value-of select="replace(string-join($input//text()/normalize-space(), ' '), '\s', '')"/>
    </xsl:function>
    
    
    <xsl:function name="mdc:find-the-ultimate-parent-id" as="xs:string">
        <!-- given that there can be multiple parent/id pairings, this occasionally recursive function will find and select the top container ID attribute, which will be used to do the groupings, rather than depending on entirely document order -->
        <xsl:param name="current-container" as="node()"/>
        <xsl:variable name="parent" select="$current-container/@parent"/>
        <xsl:choose>
            <xsl:when test="not ($parent)">
                <xsl:value-of select="$current-container/@id"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="mdc:find-the-ultimate-parent-id($current-container/preceding-sibling::ead3:container[@id eq $parent])"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    
    <xsl:function name="mdc:top-container-to-number" as="xs:decimal">
        <xsl:param name="current-container" as="node()*"/>
        <xsl:variable name="primary-container-number" select="if (contains($current-container, '-')) then replace(substring-before($current-container, '-'), '\D', '') else replace($current-container, '\D', '')"/>
        <xsl:variable name="primary-container-modify">
            <xsl:choose>
                <xsl:when test="matches($current-container, '\D')">
                    <xsl:analyze-string select="$current-container" regex="(\D)(\s?)">
                        <xsl:matching-substring>
                            <xsl:value-of select="number(string-to-codepoints(upper-case(regex-group(1))))"/>
                        </xsl:matching-substring>
                    </xsl:analyze-string>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="00"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="xs:decimal(concat($primary-container-number, '.', $primary-container-modify))"/>
    </xsl:function>
    
    
    <!-- header and footer templates (start)-->
    <xsl:template name="header-right">
        <fo:block text-align="right" font-size="9pt">
            <xsl:apply-templates select="$collection-title"/>
            <fo:block/>
            <xsl:apply-templates select="$collection-identifier"/>
        </fo:block>
    </xsl:template>
    <xsl:template name="header-dsc">
        <fo:block text-align="left">
            <fo:inline-container width="39%">
                <fo:block font-size="9pt">
                    <!-- add as a config option -->
                    <xsl:text>Johnson Publishing Company Archive</xsl:text>
                </fo:block>
            </fo:inline-container>
            <fo:inline-container width="61%">
                <xsl:call-template name="header-right"/>
            </fo:inline-container>
        </fo:block>
    </xsl:template>
    <xsl:template name="footer">
        <fo:block xsl:use-attribute-sets="page-number" text-align="center" padding-top="10pt">
            <xsl:text>Page </xsl:text>
            <fo:page-number/>
            <xsl:text> of </xsl:text>
            <fo:page-number-citation ref-id="last-page"/>
        </fo:block>
    </xsl:template>
    <!-- header and footer templates (end)-->
    
    <!-- archdesc named templates (start)-->
    <!-- all labels should be pulled from a configuration file, instead, with i18n options -->
    <xsl:template name="holding-repository">
        <fo:list-item xsl:use-attribute-sets="collection-overview-list-item">
            <fo:list-item-label xsl:use-attribute-sets="collection-overview-list-label">
                <fo:block>
                    <xsl:text>Repository: </xsl:text>
                </fo:block>
            </fo:list-item-label>
            <fo:list-item-body xsl:use-attribute-sets="collection-overview-list-body">
                <fo:block>
                    <xsl:value-of select="$holding-repository/normalize-space()"/>
                </fo:block>
                <xsl:apply-templates select="ancestor::ead3:ead/ead3:control/ead3:filedesc/ead3:publicationstmt/ead3:address"/>
            </fo:list-item-body>
        </fo:list-item>
    </xsl:template>
    
    <xsl:template name="finding-aid-summary">
        <fo:list-item xsl:use-attribute-sets="collection-overview-list-item">
            <fo:list-item-label xsl:use-attribute-sets="collection-overview-list-label">
                <fo:block>
                    <xsl:text>Summary: </xsl:text>
                </fo:block>
            </fo:list-item-label>
            <fo:list-item-body xsl:use-attribute-sets="collection-overview-list-body">
                <fo:block>
                    <xsl:apply-templates select="$finding-aid-summary"/>
                </fo:block>
            </fo:list-item-body>
        </fo:list-item>
    </xsl:template>
    
    <xsl:template name="finding-aid-link">
        <fo:list-item xsl:use-attribute-sets="collection-overview-list-item">
            <fo:list-item-label xsl:use-attribute-sets="collection-overview-list-label">
                <fo:block>
                    <xsl:text>Online Finding Aid: </xsl:text>
                </fo:block>
            </fo:list-item-label>
            <fo:list-item-body xsl:use-attribute-sets="collection-overview-list-body">
                <fo:block>
                    <xsl:value-of select="$online-link-prefatory-text"/>
                    <fo:basic-link xsl:use-attribute-sets="ref" external-destination="{$online-link}"
                        fox:alt-text="Permanent finding aid link">
                        <xsl:value-of select="$online-link"/>
                    </fo:basic-link>
                </fo:block>
            </fo:list-item-body>
        </fo:list-item>
    </xsl:template>
    
    <xsl:template name="select-header">
        <!-- i'd like to add a map here instead but i think that we'd need to upgrade saxon he to do that -->
        <fo:block>
            <xsl:choose>
                <xsl:when test="self::ead3:unitid">
                    <xsl:text>Call Number: </xsl:text>
                </xsl:when>
                <xsl:when test="self::ead3:origination">
                    <xsl:text>Creator: </xsl:text>
                </xsl:when>
                <xsl:when test="self::ead3:unittitle">
                    <xsl:text>Title: </xsl:text>
                </xsl:when>
                <xsl:when test="self::ead3:unitdatestructured[not(@unitdatetype='bulk')]">
                    <xsl:text>Dates: </xsl:text>
                </xsl:when>
                <xsl:when test="self::ead3:unitdatestructured[@unitdatetype='bulk']">
                    <xsl:text>Bulk Dates: </xsl:text>
                </xsl:when>
                <xsl:when test="self::ead3:physdescstructured">
                    <xsl:text>Physical Description: </xsl:text>
                </xsl:when>
                <xsl:when test="self::ead3:langmaterial">
                    <xsl:text>Language: </xsl:text>
                </xsl:when>
                <xsl:when test="self::ead3:physloc">
                    <xsl:text>Location: </xsl:text>
                </xsl:when>
                <xsl:when test="self::ead3:materialspec">
                    <xsl:text>Technical: </xsl:text>
                </xsl:when>
            </xsl:choose>
        </fo:block>
    </xsl:template>
    <!-- archdesc named templates (end)-->
    
    <xsl:template name="combine-identifier-title-and-dates">
        <xsl:apply-templates select="ead3:did/ead3:unitid"/>
        <xsl:if test="ead3:did/ead3:unitid/normalize-space()">
            <xsl:value-of select="$unitid-separator"/>
        </xsl:if>
        <xsl:apply-templates select="ead3:did/ead3:unittitle"/>
        <xsl:if test="ead3:did/ead3:unittitle and (ead3:did/ead3:unitdatestructured | ead3:did/ead3:unitdate)">
            <xsl:text>, </xsl:text>
        </xsl:if>
        <xsl:apply-templates select="ead3:did/ead3:unitdatestructured | ead3:did/ead3:unitdate"/>
    </xsl:template>
    
    <!-- dsc named templates (start)-->
    <xsl:template name="dsc-block-identifier-and-title">
        <xsl:choose>
            <xsl:when test="(@level = $levels-to-include-in-toc) or (@otherlevel = otherlevels-to-include-in-toc)">
                <xsl:apply-templates select="ead3:did/ead3:unitid"/>
                <xsl:if test="ead3:did/ead3:unitid/normalize-space()">
                    <xsl:value-of select="$unitid-separator"/>
                </xsl:if>
                <xsl:apply-templates select="if (ead3:did/ead3:unittitle) then ead3:did/ead3:unittitle 
                    else ead3:did/ead3:unitdatestructured | ead3:did/ead3:unitdate" mode="dsc"/> 
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="if (ead3:did/ead3:unittitle) then ead3:did/ead3:unittitle 
                    else ead3:did/ead3:unitdatestructured | ead3:did/ead3:unitdate" mode="dsc"/>
                <!-- let's add a line break rather than a space. -->
                <fo:block/>
                <xsl:apply-templates select="ead3:did/ead3:unitid"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- still neeed options for when dates and/or containers aren't present in a table -->
    <xsl:template name="tableBody">
        <xsl:param name="column-types"/>
        <xsl:param name="depth" select="0"/>
        <xsl:param name="cell-margin"/>
        <fo:table inline-progression-dimension="100%" table-layout="fixed" font-size="9pt"
            border-collapse="collapse" keep-with-previous.within-page="always" table-omit-header-at-break="{$dsc-omit-table-header-at-break}">          
            <xsl:choose>
                <xsl:when test="$column-types eq 'c-d-d'">
                    <fo:table-column column-number="1" column-width="proportional-column-width(15)"/>
                    <fo:table-column column-number="2" column-width="proportional-column-width(70)"/>
                    <fo:table-column column-number="3" column-width="proportional-column-width(15)"/>
                </xsl:when>
                <xsl:when test="$column-types eq 'd-d'">
                     <fo:table-column column-number="1" column-width="proportional-column-width(75)"/>
                     <fo:table-column column-number="2" column-width="proportional-column-width(25)"/>
                </xsl:when>
                <xsl:when test="$column-types eq 'c-d'">
                    <fo:table-column column-number="1" column-width="proportional-column-width(15)"/>
                    <fo:table-column column-number="2" column-width="proportional-column-width(85)"/>
                </xsl:when>
                <xsl:otherwise>
                    <fo:table-column column-number="1" column-width="proportional-column-width(100)"/>
                </xsl:otherwise>
            </xsl:choose>
            <xsl:call-template name="tableHeaders">
                <xsl:with-param name="cell-margin" select="$cell-margin"/>
                <xsl:with-param name="column-types" select="$column-types"/>
            </xsl:call-template>
            <fo:table-body>
                <xsl:apply-templates select="ead3:*[matches(local-name(), '^c0|^c1') or local-name()='c']" mode="dsc-table">
                    <xsl:with-param name="depth" select="$depth"/>
                    <xsl:with-param name="column-types" select="$column-types"/>
                </xsl:apply-templates>
            </fo:table-body>
        </fo:table>
    </xsl:template>
    
    <xsl:template name="tableHeaders">
        <xsl:param name="cell-margin"/>
        <xsl:param name="column-types"/>
        <xsl:variable name="columns-spanned" select="string-length(replace($column-types, '-', ''))"/>
        <!-- xsl:use-attribute-sets="dsc-table-header" -->
        <fo:table-header>
            <fo:table-row>
                <xsl:choose>
                    <xsl:when test="$column-types = ('c-d-d', 'c-d')">
                        <fo:table-cell>
                            <fo:block/>
                        </fo:table-cell>
                        <fo:table-cell number-columns-spanned="{$columns-spanned -1 }">
                            <fo:block font-size="9pt">
                                <fo:retrieve-table-marker retrieve-class-name="continued-text" 
                                    retrieve-position-within-table="first-starting" 
                                    retrieve-boundary-within-table="table-fragment"/> 
                                &#x00A0;
                            </fo:block>
                        </fo:table-cell>
                    </xsl:when>
                    <xsl:otherwise>
                        <fo:table-cell number-columns-spanned="{$columns-spanned}">
                            <fo:block font-size="9pt">
                                <fo:retrieve-table-marker retrieve-class-name="continued-text" 
                                    retrieve-position-within-table="first-starting" 
                                    retrieve-boundary-within-table="table-fragment"/> 
                                &#x00A0;
                            </fo:block>
                        </fo:table-cell>
                    </xsl:otherwise>
                </xsl:choose>
            </fo:table-row>
            <fo:table-row>
                <fo:table-cell number-columns-spanned="{$columns-spanned}">
                    <fo:block>
                        &#x00A0;
                    </fo:block>
                </fo:table-cell>
            </fo:table-row>
            <!-- a bit of a hack to hide the column headers here, using "white font", but i don't think they're needed
            for the visual layout of the PDF. -->
            <fo:table-row xsl:use-attribute-sets="white-font">
                <xsl:choose>
                    <xsl:when test="$column-types eq 'c-d-d'">
                        <fo:table-cell>
                            <fo:block>Container</fo:block>
                        </fo:table-cell>
                        <fo:table-cell>
                            <fo:block>Description</fo:block>
                        </fo:table-cell>
                        <fo:table-cell>
                            <fo:block>Date</fo:block>
                        </fo:table-cell>      
                    </xsl:when>
                    <xsl:when test="$column-types eq 'd-d'">
                        <fo:table-cell>
                            <fo:block>Description</fo:block>
                        </fo:table-cell>
                        <fo:table-cell>
                            <fo:block>Date</fo:block>
                        </fo:table-cell>   
                    </xsl:when>
                    <xsl:when test="$column-types eq 'c-d'">
                        <fo:table-cell>
                            <fo:block>Container</fo:block>
                        </fo:table-cell>
                        <fo:table-cell>
                            <fo:block>Description</fo:block>
                        </fo:table-cell>   
                    </xsl:when>
                    <xsl:otherwise>
                        <fo:table-cell>
                            <fo:block>Description</fo:block>
                        </fo:table-cell>  
                    </xsl:otherwise>
                </xsl:choose>
            </fo:table-row>
        </fo:table-header>
    </xsl:template>
    
    <xsl:template name="dsc-table-row-border">
        <xsl:param name="last-row"/>
        <xsl:param name="no-children"/>
        <xsl:param name="audience"/>
        <xsl:param name="component-string-length"/>
        <xsl:if test="$component-string-length lt 2000">
            <xsl:attribute name="keep-together.within-column">always</xsl:attribute>
        </xsl:if>
        <xsl:choose>
            <xsl:when test="$suppressInternalComponentsInPDF eq false() and $audience eq 'internal'">
                <xsl:attribute name="border-style">solid</xsl:attribute>
                <xsl:attribute name="border-width">2px</xsl:attribute>
                <xsl:attribute name="border-color">red</xsl:attribute>
            </xsl:when>
            <xsl:otherwise>
                <xsl:if test="$last-row or $no-children">
                    <xsl:attribute name="border-bottom-style">solid</xsl:attribute>
                    <xsl:attribute name="border-bottom-width">0.1mm</xsl:attribute>
                </xsl:if>
                <xsl:choose>
                    <xsl:when test="$last-row">
                        <xsl:attribute name="border-bottom-color">#dddddd</xsl:attribute>
                    </xsl:when>
                    <xsl:when test="$no-children">
                        <xsl:attribute name="border-bottom-color">#dddddd</xsl:attribute>
                    </xsl:when>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    <!-- not sure how to handle this yet, but ideally i'd like to include extra blocks of text
        to indicate when the table is continued -->
    <xsl:template name="ancestor-info">
        <!-- allow for longer c01 - c03 headings, and then make it smaller from there -->
        <xsl:param name="longest-length-allowed" select="64"/>
        <xsl:variable name="immediate-ancestor" select="ancestor::ead3:*[ead3:did/ead3:unittitle][ancestor::ead3:dsc][1]"/>
        <xsl:variable name="folder-title-plus-unitid">
            <xsl:choose>
                <!-- if there's just a unitid, use that in place of the title and don't inherit anything.
                            the "inherited" title will still appear as an ancestor title on the label due to the sequence-of-series -->
                <xsl:when test="not(ead3:did/ead3:unittitle[normalize-space()]) and ead3:did/ead3:unitid[normalize-space()][not(@audience='internal')]">
                    <xsl:value-of select="ead3:did/ead3:unitid[not(@audience='internal')][1]"/>
                </xsl:when>
                <!-- if there's no unitid or title, then grab an ancestor title and unitid, since 
                            the component might only have a unitdate.  later, we'll filter this out of the sequence-of-series list of titles. -->
                <xsl:when test="not(ead3:did/ead3:unittitle[normalize-space()])">
                    <xsl:if test="$immediate-ancestor[ead3:did/ead3:unitid]">
                        <xsl:value-of select="concat($immediate-ancestor/ead3:did/ead3:unitid[not(@audience='internal')][1], $unitid-separator)"/>
                    </xsl:if>
                    <xsl:value-of select="$immediate-ancestor/ead3:did/ead3:unittitle[1]"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:if test="normalize-space(ead3:did/ead3:unitid[not(@audience='internal')][1])">
                        <xsl:value-of select="normalize-space(ead3:did/ead3:unitid[not(@audience='internal')][1])"/>
                        <xsl:value-of select="$unitid-separator"/>
                    </xsl:if>
                    <xsl:value-of select="normalize-space(ead3:did/ead3:unittitle[1])"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <!-- rewrite this.   should be no need to do the hacky string-stuff, especially once we upgrade to xslt3 (nor now, but...) -->
        <xsl:variable name="ancestor-sequence">
            <xsl:sequence select="string-join(
                for $ancestor in ancestor::*[ead3:did][ancestor::ead3:dsc] return 
                if ($ancestor/ead3:did/ead3:unitid/not(ends-with(normalize-space(), $unitid-trailing-punctuation))
                and $ancestor/lower-case(@level) = ('series', 'subseries')) 
                then concat($ancestor/ead3:did/ead3:unitid/normalize-space(), $unitid-separator, $ancestor/ead3:did/ead3:unittitle/normalize-space())
                else if ($ancestor/ead3:did/ead3:unitid/normalize-space())
                then concat($ancestor/ead3:did/ead3:unitid/normalize-space(), ' ', $ancestor/ead3:did/ead3:unittitle/normalize-space())
                else $ancestor/ead3:did/ead3:unittitle/normalize-space()
                , 'xx*****yz')"/>
        </xsl:variable>
        <xsl:variable name="ancestor-sequence-filtered">
            <xsl:sequence select="string-join(remove($ancestor-sequence
                , if (exists(index-of($ancestor-sequence, $folder-title-plus-unitid))) 
                then index-of($ancestor-sequence, $folder-title-plus-unitid)
                else 0)
                , 'xx*****yz')"/>
        </xsl:variable>
        <xsl:variable name="series-of-series" select="if (contains($ancestor-sequence-filtered, 'xx*****yz'))
            then tokenize($ancestor-sequence-filtered, 'xx\*\*\*\*\*yz') else $ancestor-sequence-filtered"/>
        <!-- mdc: since we include the series name in the page header, let's see what it looks like without that here in the table header 
        if folks don't like that, just remove the position() filter
        -->
        <xsl:for-each select="$series-of-series[normalize-space()]">
            <fo:inline>
                <xsl:value-of select="if (string-length(.) gt $longest-length-allowed) 
                    then concat(substring(., 1, $longest-length-allowed), ' [...]') 
                    else ."/>
                <xsl:if test="position() ne last()">
                    <xsl:text> > </xsl:text>
                </xsl:if>
                <xsl:if test="position() eq last()">
                    <xsl:text> (continued)</xsl:text>
                </xsl:if>
            </fo:inline>
        </xsl:for-each>
    </xsl:template>
    
    <xsl:template name="container-layout">
        <xsl:param name="containers-sorted-by-localtype"/>
        <fo:block xsl:use-attribute-sets="table-container-column">
            <xsl:apply-templates select="$containers-sorted-by-localtype/*/container-group"/>
        </fo:block> 
    </xsl:template>
    
    <xsl:template match="container-group">
        <xsl:choose>
            <!-- when more than one container per group, let's collapse the range for the display -->
            <xsl:when test="not(ead3:container/@parent) and ead3:container[2]">
                <xsl:for-each select="ead3:container[1]">
                    <xsl:call-template name="get-container-prefix-info">
                        <xsl:with-param name="container-lower-case" select="lower-case(@localtype)"/>
                    </xsl:call-template>
                </xsl:for-each>
                <xsl:apply-templates select="ead3:container[1]" mode="collapse-containers"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates/>
            </xsl:otherwise>
        </xsl:choose>
        
    </xsl:template>
    
    <xsl:template name="get-container-prefix-info">
        <xsl:param name="container-lower-case"/>
        
        <!-- have 4 options below, but this example only demonstrates 1... which won't ever be in the source data... so, just an example -->
        <xsl:variable name="use-fontawesome" as="xs:boolean">
            <xsl:value-of select="if ($container-lower-case = ('item_barcode')) then true() else false()"/>
        </xsl:variable>
        <!-- removed all options for abbreviation...  could use values like 'box', 'folder', etc. -->
        <xsl:variable name="container-abbr">
            <xsl:value-of select="if ($container-lower-case = ('')) then concat(substring($container-lower-case, 1, 1), '.')
                else ''"/>
        </xsl:variable>
        
        <xsl:choose>
            <xsl:when test="$use-fontawesome eq false()">
                <fo:inline color="#4A4A4A">
                    <xsl:if test="$container-abbr/normalize-space()">
                        <xsl:attribute name="alt-text" namespace="http://xmlgraphics.apache.org/fop/extensions" select="$container-lower-case"/>
                    </xsl:if>
                    <xsl:value-of select="if ($container-abbr/normalize-space()) then $container-abbr else $container-lower-case"/>
                </fo:inline>
            </xsl:when>
            <xsl:otherwise>
                <fo:inline font-family="FontAwesomeSolid" color="#4A4A4A">
                    <xsl:value-of select="if ($container-lower-case eq 'box') then '&#xf187; '
                        else if ($container-lower-case eq 'folder') then '&#xf07b; '
                        else if ($container-lower-case eq 'volume') then '&#xf02d; '
                        else if ($container-lower-case eq 'item_barcode') then '&#xf02a;'
                        else '&#xf0a0; '"/>
                </fo:inline>
                <fo:inline color="#4A4A4A">
                    <xsl:if test="$container-abbr/normalize-space()">
                        <xsl:attribute name="alt-text" namespace="http://xmlgraphics.apache.org/fop/extensions" select="$container-lower-case"/>
                    </xsl:if>
                    <xsl:value-of select="if ($container-lower-case eq 'item_barcode') then ''
                        else if ($container-abbr/normalize-space()) then $container-abbr
                        else $container-lower-case"/>
                </fo:inline>
            </xsl:otherwise>
        </xsl:choose>
        <xsl:text> </xsl:text>   
    </xsl:template>
    
    
    <!-- dsc named templates (end) -->
    
    <xsl:template name="section-start">
        <fo:block keep-with-next.within-page="always">
            <fo:leader leader-pattern="rule"
                rule-thickness="0.75pt"
                leader-length="7.25in"/>
        </fo:block>
    </xsl:template>
      
     
     <!-- not used here, but keeping around in case we ever need something similar in this output -->
     <xsl:template name="dsc-container-abbr-key">
         <xsl:param name="container-localtypes"/>
         <fo:block margin="1em 0">
             <fo:block>Key to the container abbreviations used in the PDF finding aid:</fo:block>
             <fo:list-block 
                 font-size="9pt" 
                 provisional-distance-between-starts="4em"
                 provisional-label-separation="1em"
                 margin-top="0.5em">
                 <xsl:if test="$container-localtypes = 'box'">
                     <fo:list-item>
                         <fo:list-item-label xsl:use-attribute-sets="dsc-container-key-list-label">
                             <fo:block color="#4A4A4A">b.</fo:block>
                         </fo:list-item-label>
                         <fo:list-item-body xsl:use-attribute-sets="collection-overview-list-body">
                             <fo:block>box</fo:block>
                         </fo:list-item-body>
                     </fo:list-item>
                 </xsl:if>
                 <xsl:if test="$container-localtypes = 'folder'">
                     <fo:list-item>
                         <fo:list-item-label xsl:use-attribute-sets="dsc-container-key-list-label"><fo:block color="#4A4A4A">f.</fo:block></fo:list-item-label>
                         <fo:list-item-body xsl:use-attribute-sets="collection-overview-list-body"><fo:block>folder</fo:block></fo:list-item-body>
                     </fo:list-item>
                 </xsl:if>
                 <xsl:if test="$container-localtypes = 'item_barcode'">
                     <fo:list-item>
                         <fo:list-item-label xsl:use-attribute-sets="dsc-container-key-list-label">>
                             <fo:block font-family="FontAwesomeSolid" color="#4A4A4A">
                                 <xsl:text>&#xf02a;</xsl:text>
                             </fo:block>
                         </fo:list-item-label>
                         <fo:list-item-body xsl:use-attribute-sets="collection-overview-list-body"><fo:block>item barcode</fo:block></fo:list-item-body>
                     </fo:list-item> 
                 </xsl:if>
                 <xsl:if test="$container-localtypes = 'volume'">
                     <fo:list-item>
                         <fo:list-item-label xsl:use-attribute-sets="dsc-container-key-list-label">>
                             <fo:block>
                                 <fo:inline font-family="FontAwesomeSolid" color="#4A4A4A">
                                     <xsl:value-of select="'&#xf02d;'"/>
                                 </fo:inline>
                                 <fo:inline color="#4A4A4A">
                                     <xsl:text> vol.</xsl:text>
                                 </fo:inline>
                             </fo:block>
                         </fo:list-item-label>
                         <fo:list-item-body xsl:use-attribute-sets="collection-overview-list-body"><fo:block>volume</fo:block></fo:list-item-body>
                     </fo:list-item>
                 </xsl:if>
             </fo:list-block>
         </fo:block>
     </xsl:template>
    
</xsl:stylesheet>
