<?xml version="1.0" encoding="ISO-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:n1="http://www.metalinker.org/">
<xsl:output method="text" indent="no" omit-xml-declaration="yes" encoding="UTF-8"/>
  <xsl:template match="/">
    <xsl:for-each select="n1:metalink/n1:files/n1:file/n1:resources">
      <xsl:value-of select="n1:url">
      </xsl:value-of>
<xsl:text>
</xsl:text>
    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>
