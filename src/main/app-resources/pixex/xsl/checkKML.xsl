<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="text" version="1.0" encoding="UTF-8" indent="no" />
<xsl:template match="Placemarks">
<xsl:choose>
 <xsl:when test="/Placemarks/Placemark">true</xsl:when>
 <xsl:otherwise>false</xsl:otherwise>
</xsl:choose>
</xsl:template>
<xsl:template match="*"/>
</xsl:stylesheet>
