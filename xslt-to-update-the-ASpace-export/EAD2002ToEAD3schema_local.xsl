<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns="http://ead3.archivists.org/schema/"
    exclude-result-prefixes="xs math"
    version="3.0">
    
    <!-- go with a cached copy.  lesson learned on plane -->
    <xsl:import href="https://raw.githubusercontent.com/SAA-SDT/EAD2002toEAD3/f3546dbf83d17b1c22b79a48bdaaa954b94dbb75/xslt/EAD2002ToEAD3schema.xsl"/>
    
    <!-- to do:  add an override to handle:
        
                   <userestrict altrender="Mixed" id="aspace_ae75e699cf49878aa1efd7b9bef5098e" type="other">
              <head>Rights Statement</head>
              <note type="type_note">
                <p>Some or all of the photos in this folder maybe subject to copyright or other
                  intellectual property rights.</p>
              </note>
    With the default process, we wind up with a "footnote" element here
    -->
    
    <!-- local overrides -->
    <xsl:param name="addMigrationComments" select="false()"/>
    <xsl:param name="addMigrationMessages" select="false()"/>
    <xsl:param name="schemaPath" select="'https://www.loc.gov/ead/'"/>
    
    <!-- new, to achieve validity, due to stripping of "aspace_" preference in JPCA ASpace -->
    <xsl:template match="@id | @target | @parent">
        <xsl:attribute name="{name(.)}">
            <xsl:value-of select="'ead3_' || ."/>
        </xsl:attribute>
    </xsl:template>
    
    <!-- Oh, ASpace! -->
    <xsl:template match="titleproper/num"/>
    
    <!-- new, so that we don't have to deal with both structured and unstructured archdesc elements in the PDF transformation step -->
    <xsl:template match="archdesc/did/physdesc">
        <physdescstructured coverage="{@altrender}" physdescstructuredtype="{(extent/@altrender/substring-after(., ' '), extent/@altrender)[1]}">
            <quantity>
                <xsl:value-of select="substring-before(extent[1], ' ')"/>
            </quantity>
            <unittype>
                <xsl:value-of select="substring-after(extent[1], ' ')"/>
            </unittype>
            <xsl:apply-templates select="physfacet, dimensions"/>
        </physdescstructured>
        <xsl:apply-templates select="extent[2][@altrender='carrier']"/>
    </xsl:template>
 
    <xsl:template match="archdesc/did/physdesc/extent[2][@altrender='carrier']">
        <physdesc localtype="container_summary">
            <xsl:apply-templates/>
        </physdesc>
    </xsl:template>
    
    <xsl:template match="archdesc/did/unitdate">
        <unitdatestructured datechar="{@datechar}" unitdatetype="{@type}" altrender="{normalize-space(.)}">
           <xsl:choose>
               <xsl:when test="contains(@normal, '/')">
                   <xsl:variable name="startdate" select="substring-before(@normal, '/')"/>
                   <xsl:variable name="enddate" select="substring-after(@normal, '/')"/>
                   <daterange>
                       <fromdate standarddate="{$startdate}">
                           <xsl:value-of select="$startdate"/>
                       </fromdate>
                       <todate standarddate="{$enddate}">
                           <xsl:value-of select="$enddate"/>
                       </todate>
                   </daterange>
               </xsl:when>
               <xsl:otherwise>
                   <datesingle>
                       <xsl:apply-templates/>
                   </datesingle>
               </xsl:otherwise>
           </xsl:choose>

        </unitdatestructured>
    </xsl:template>
    
    <!-- no need to add footnotes, as per the default EAD2002 to 3 transform -->    
    <xsl:template match="userestrict[head eq 'Rights Statement']/note[@type eq 'type_note']">
        <xsl:apply-templates/>
    </xsl:template>

    
</xsl:stylesheet>