<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:ns="https://www.metanorma.org/ns/standoc" xmlns:mathml="http://www.w3.org/1998/Math/MathML" xmlns:xalan="http://xml.apache.org/xalan" xmlns:fox="http://xmlgraphics.apache.org/fop/extensions" xmlns:pdf="http://xmlgraphics.apache.org/fop/extensions/pdf" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:java="http://xml.apache.org/xalan/java" exclude-result-prefixes="java" version="1.0">

	<!-- NOTE: change xmlns:ns="https://www.metanorma.org/ns/iso" to xml document namespace -->

	<xsl:output method="xml" encoding="UTF-8" indent="no"/>
	
	<xsl:param name="svg_images"/>
	<xsl:param name="external_index"/> <!-- path to index xml, generated on 1st pass, based on FOP Intermediate Format -->
	
	<xsl:variable name="images" select="document($svg_images)"/>
	
	<xsl:param name="basepath"/>
	
	<xsl:key name="kfn" match="ns:p/ns:fn" use="@reference"/>
	<xsl:key name="attachments" match="ns:eref[contains(@bibitemid, '.exp')]" use="@bibitemid"/>
	
	<xsl:variable name="debug">false</xsl:variable>
	
	<xsl:variable name="pageWidth" select="210"/>
	<xsl:variable name="pageHeight" select="297"/>
	<xsl:variable name="marginLeftRight1" select="25"/>
	<xsl:variable name="marginLeftRight2" select="12.5"/>
	<xsl:variable name="marginTop" select="27.4"/>
	<xsl:variable name="marginBottom" select="13"/>
	
	<xsl:variable name="docidentifierISO" select="/*/ns:bibdata/ns:docidentifier[@type = 'iso'] | /*/ns:bibdata/ns:docidentifier[@type = 'ISO']"/>
	<xsl:variable name="all_rights_reserved">
		<xsl:call-template name="getLocalizedString">
			<xsl:with-param name="key">all_rights_reserved</xsl:with-param>
		</xsl:call-template>
	</xsl:variable>
	
	<xsl:variable name="copyrightText" select="concat('© ISO ', /*/ns:bibdata/ns:copyright/ns:from ,' – ', $all_rights_reserved)"/>
	<xsl:variable name="ISOname" select="/*/ns:bibdata/ns:docidentifier[@type = 'iso-reference']"/>
	<xsl:variable name="title-intro" select="/*/ns:bibdata/ns:title[@language = 'en' and @type = 'title-intro']"/>
	<xsl:variable name="title-intro-fr" select="/*/ns:bibdata/ns:title[@language = 'fr' and @type = 'title-intro']"/>
	<xsl:variable name="title-main" select="/*/ns:bibdata/ns:title[@language = 'en' and @type = 'title-main']"/>
	<xsl:variable name="title-main-fr" select="/*/ns:bibdata/ns:title[@language = 'fr' and @type = 'title-main']"/>
	<xsl:variable name="part" select="/*/ns:bibdata/ns:ext/ns:structuredidentifier/ns:project-number/@part"/>
	<xsl:variable name="doctype" select="/*/ns:bibdata/ns:ext/ns:doctype"/>
	<xsl:variable name="doctype_uppercased" select="java:toUpperCase(java:java.lang.String.new(translate($doctype,'-',' ')))"/>
	<xsl:variable name="stagename" select="normalize-space(/*/ns:bibdata/ns:ext/ns:stagename)"/>
	<xsl:variable name="stage-fullname-uppercased" select="java:toUpperCase(java:java.lang.String.new($stagename))"/>
	
	<!-- Example:
		<item level="1" id="Foreword" display="true">Foreword</item>
		<item id="term-script" display="false">3.2</item>
	-->
	<xsl:variable name="contents">
		<contents>
			<xsl:call-template name="processPrefaceSectionsDefault_Contents"/>
			<xsl:call-template name="processMainSectionsDefault_Contents"/>
			<xsl:apply-templates select="//ns:indexsect" mode="contents"/>
		</contents>
	</xsl:variable>
	
	<xsl:variable name="lang">
		<xsl:call-template name="getLang"/>
	</xsl:variable>
	
	<xsl:template match="/">
		<fo:root xsl:use-attribute-sets="root-style" xml:lang="{$lang}">
			<fo:layout-master-set>
				<!-- cover page -->
				<fo:simple-page-master master-name="cover-page-odd" page-width="{$pageWidth}mm" page-height="{$pageHeight}mm">
					<fo:region-body margin-top="12.7mm" margin-bottom="40mm" margin-left="{$marginLeftRight1}mm" margin-right="{$marginLeftRight2}mm"/>
					<fo:region-before region-name="cover-page-header" extent="12.7mm"/>
					<fo:region-after region-name="cover-page-footer" extent="40mm" display-align="after"/>
					<fo:region-start region-name="cover-left-region" extent="{$marginLeftRight1}mm"/>
					<fo:region-end region-name="cover-right-region" extent="{$marginLeftRight2}mm"/>
				</fo:simple-page-master>
				<fo:simple-page-master master-name="cover-page-even" page-width="{$pageWidth}mm" page-height="{$pageHeight}mm">
					<fo:region-body margin-top="12.7mm" margin-bottom="40mm" margin-left="{$marginLeftRight2}mm" margin-right="{$marginLeftRight1}mm"/>
					<fo:region-before region-name="cover-page-header" extent="12.7mm"/>
					<fo:region-after region-name="cover-page-footer" extent="40mm" display-align="after"/>
					<fo:region-start region-name="cover-left-region" extent="{$marginLeftRight2}mm"/>
					<fo:region-end region-name="cover-right-region" extent="{$marginLeftRight1}mm"/>
				</fo:simple-page-master>
				<fo:page-sequence-master master-name="cover-page">
					<fo:repeatable-page-master-alternatives>
						<fo:conditional-page-master-reference odd-or-even="even" master-reference="cover-page-even"/>
						<fo:conditional-page-master-reference odd-or-even="odd" master-reference="cover-page-odd"/>
					</fo:repeatable-page-master-alternatives>
				</fo:page-sequence-master>
				<!-- first page -->
				<fo:simple-page-master master-name="first" page-width="{$pageWidth}mm" page-height="{$pageHeight}mm">
					<fo:region-body margin-top="{$marginTop}mm" margin-bottom="{$marginBottom}mm" margin-left="{$marginLeftRight1}mm" margin-right="{$marginLeftRight2}mm"/>
					<fo:region-before region-name="header-first" extent="{$marginTop}mm"/>
					<!--   display-align="center" -->
					<fo:region-after region-name="footer-odd" extent="{$marginBottom}mm"/>
					<fo:region-start region-name="left-region" extent="{$marginLeftRight1}mm"/>
					<fo:region-end region-name="right-region" extent="{$marginLeftRight2}mm"/>
				</fo:simple-page-master>
				<!-- odd pages -->
				<fo:simple-page-master master-name="odd" page-width="{$pageWidth}mm" page-height="{$pageHeight}mm">
					<fo:region-body margin-top="{$marginTop}mm" margin-bottom="{$marginBottom}mm" margin-left="{$marginLeftRight1}mm" margin-right="{$marginLeftRight2}mm"/>
					<fo:region-before region-name="header-odd" extent="{$marginTop}mm"/>
					<!--   display-align="center" -->
					<fo:region-after region-name="footer-odd" extent="{$marginBottom}mm"/>
					<fo:region-start region-name="left-region" extent="{$marginLeftRight1}mm"/>
					<fo:region-end region-name="right-region" extent="{$marginLeftRight2}mm"/>
				</fo:simple-page-master>
				<!-- even pages -->
				<fo:simple-page-master master-name="even" page-width="{$pageWidth}mm" page-height="{$pageHeight}mm">
					<fo:region-body margin-top="{$marginTop}mm" margin-bottom="{$marginBottom}mm" margin-left="{$marginLeftRight2}mm" margin-right="{$marginLeftRight1}mm"/>
					<fo:region-before region-name="header-even" extent="{$marginTop}mm"/>
					<fo:region-after region-name="footer-even" extent="{$marginBottom}mm"/>
					<fo:region-start region-name="left-region" extent="{$marginLeftRight2}mm"/>
					<fo:region-end region-name="right-region" extent="{$marginLeftRight1}mm"/>
				</fo:simple-page-master>
				<fo:simple-page-master master-name="blankpage" page-width="{$pageWidth}mm" page-height="{$pageHeight}mm">
					<fo:region-body margin-top="{$marginTop}mm" margin-bottom="{$marginBottom}mm" margin-left="{$marginLeftRight2}mm" margin-right="{$marginLeftRight1}mm"/>
					<fo:region-before region-name="header" extent="{$marginTop}mm"/>
					<fo:region-after region-name="footer" extent="{$marginBottom}mm"/>
					<fo:region-start region-name="left" extent="{$marginLeftRight2}mm"/>
					<fo:region-end region-name="right" extent="{$marginLeftRight1}mm"/>
				</fo:simple-page-master>
				<fo:page-sequence-master master-name="preface">
					<fo:repeatable-page-master-alternatives>
						<fo:conditional-page-master-reference master-reference="blankpage" blank-or-not-blank="blank"/>
						<fo:conditional-page-master-reference odd-or-even="even" master-reference="even"/>
						<fo:conditional-page-master-reference odd-or-even="odd" master-reference="odd"/>
					</fo:repeatable-page-master-alternatives>
				</fo:page-sequence-master>
				<fo:page-sequence-master master-name="document">
					<fo:repeatable-page-master-alternatives>
						<fo:conditional-page-master-reference master-reference="first" page-position="first"/>
						<fo:conditional-page-master-reference odd-or-even="even" master-reference="even"/>
						<fo:conditional-page-master-reference odd-or-even="odd" master-reference="odd"/>
					</fo:repeatable-page-master-alternatives>
				</fo:page-sequence-master>
				<fo:simple-page-master master-name="last-page" page-width="{$pageWidth}mm" page-height="{$pageHeight}mm">
					<fo:region-body margin-top="{$marginTop}mm" margin-bottom="{$marginBottom}mm" margin-left="{$marginLeftRight2}mm" margin-right="{$marginLeftRight1}mm"/>
					<fo:region-before region-name="header-even" extent="{$marginTop}mm"/>
					<fo:region-after region-name="last-page-footer" extent="{$marginBottom}mm"/>
					<fo:region-start region-name="left-region" extent="{$marginLeftRight2}mm"/>
					<fo:region-end region-name="right-region" extent="{$marginLeftRight1}mm"/>
				</fo:simple-page-master>
				<!-- Index pages -->
				<fo:simple-page-master master-name="index-odd" page-width="{$pageWidth}mm" page-height="{$pageHeight}mm">
					<fo:region-body margin-top="{$marginTop}mm" margin-bottom="{$marginBottom}mm" margin-left="{$marginLeftRight1}mm" margin-right="{$marginLeftRight2}mm" column-count="2" column-gap="10mm"/>
					<fo:region-before region-name="header-odd" extent="{$marginTop}mm"/>
					<fo:region-after region-name="footer-odd" extent="{$marginBottom}mm"/>
					<fo:region-start region-name="left-region" extent="{$marginLeftRight1}mm"/>
					<fo:region-end region-name="right-region" extent="{$marginLeftRight2}mm"/>
				</fo:simple-page-master>
				<fo:simple-page-master master-name="index-even" page-width="{$pageWidth}mm" page-height="{$pageHeight}mm">
					<fo:region-body margin-top="{$marginTop}mm" margin-bottom="{$marginBottom}mm" margin-left="{$marginLeftRight2}mm" margin-right="{$marginLeftRight1}mm" column-count="2" column-gap="10mm"/>
					<fo:region-before region-name="header-even" extent="{$marginTop}mm"/>
					<fo:region-after region-name="footer-even" extent="{$marginBottom}mm"/>
					<fo:region-start region-name="left-region" extent="{$marginLeftRight2}mm"/>
					<fo:region-end region-name="right-region" extent="{$marginLeftRight1}mm"/>
				</fo:simple-page-master>
				<fo:page-sequence-master master-name="index">
					<fo:repeatable-page-master-alternatives>
						<fo:conditional-page-master-reference odd-or-even="even" master-reference="index-even"/>
						<fo:conditional-page-master-reference odd-or-even="odd" master-reference="index-odd"/>
					</fo:repeatable-page-master-alternatives>
				</fo:page-sequence-master>
			</fo:layout-master-set>
			<fo:declarations>
				<xsl:call-template name="addPDFUAmeta"/>
				<xsl:for-each select="//ns:eref[generate-id(.)=generate-id(key('attachments',@bibitemid)[1])]">
					<xsl:variable name="url" select="concat('url(file:',$basepath, @bibitemid, ')')"/>
					<pdf:embedded-file src="{$url}" filename="{@bibitemid}"/>
				</xsl:for-each>
			</fo:declarations>
			<xsl:call-template name="addBookmarks">
				<xsl:with-param name="contents" select="$contents"/>
			</xsl:call-template>
			<!-- cover page -->
			<fo:page-sequence master-reference="cover-page" force-page-count="no-force">
				<fo:static-content flow-name="cover-page-footer" font-size="10pt">
					<fo:table table-layout="fixed" width="100%">
						<fo:table-column column-width="52mm"/>
						<fo:table-column column-width="7.5mm"/>
						<fo:table-column column-width="112.5mm"/>
						<fo:table-body>
							<fo:table-row>
								<fo:table-cell font-size="6.5pt" text-align="justify" display-align="after" padding-bottom="8mm">
									<fo:block margin-top="-100mm">
										<fo:block margin-bottom="1.5mm">
											<xsl:text>THIS DOCUMENT IS A DRAFT CIRCULATED FOR COMMENT AND APPROVAL. IT IS THEREFORE SUBJECT TO CHANGE AND MAY NOT BE REFERRED TO AS AN INTERNATIONAL STANDARD UNTIL PUBLISHED AS SUCH.</xsl:text>
										</fo:block>
										<fo:block margin-bottom="1.5mm">
											<xsl:text>RECIPIENTS OF THIS DRAFT ARE INVITED TO
																SUBMIT, WITH THEIR COMMENTS, NOTIFICATION
																OF ANY RELEVANT PATENT RIGHTS OF WHICH
																THEY ARE AWARE AND TO PROVIDE SUPPORTING
																DOCUMENTATION.</xsl:text>
										</fo:block>
										<fo:block>
											<xsl:text>IN ADDITION TO THEIR EVALUATION AS
													BEING ACCEPTABLE FOR INDUSTRIAL, TECHNOLOGICAL,
													COMMERCIAL AND USER PURPOSES,
													DRAFT INTERNATIONAL STANDARDS MAY ON
													OCCASION HAVE TO BE CONSIDERED IN THE
													LIGHT OF THEIR POTENTIAL TO BECOME STANDARDS
													TO WHICH REFERENCE MAY BE MADE IN
													NATIONAL REGULATIONS.</xsl:text>
										</fo:block>
									</fo:block>
								</fo:table-cell>
								<fo:table-cell>
									<fo:block> </fo:block>
								</fo:table-cell>
								<fo:table-cell>
									<fo:block>
										<fo:table table-layout="fixed" width="100%" border-top="1mm double black" margin-bottom="3mm">
											<fo:table-column column-width="50%"/>
											<fo:table-column column-width="50%"/>
											<fo:table-body>
												<fo:table-row height="34mm">
													<fo:table-cell display-align="center">
														<fo:block text-align="left" margin-top="2mm">
															<fo:external-graphic src="{concat('data:image/png;base64,', normalize-space($Image-ISO-Logo))}" width="21mm" content-height="21mm" content-width="scale-to-fit" scaling="uniform" fox:alt-text="Image {@alt}"/>
														</fo:block>
													</fo:table-cell>
													<fo:table-cell display-align="center">
														<fo:block text-align="right">
															<!-- Reference number -->
															<fo:block>
																<xsl:call-template name="getLocalizedString">
																	<xsl:with-param name="key">reference_number</xsl:with-param>
																</xsl:call-template>
															</fo:block>
															<fo:block>
																<xsl:value-of select="$ISOname"/>
															</fo:block>
															<fo:block> </fo:block>
															<fo:block> </fo:block>
															<fo:block>
																<fo:inline font-size="9pt">©</fo:inline>
																<xsl:value-of select="concat(' ISO ', */ns:bibdata/ns:copyright/ns:from)"/>
															</fo:block>
														</fo:block>
													</fo:table-cell>
												</fo:table-row>
											</fo:table-body>
										</fo:table>
									</fo:block>
								</fo:table-cell>
							</fo:table-row>
						</fo:table-body>
					</fo:table>
				</fo:static-content>
				<fo:flow flow-name="xsl-region-body">
					<fo:block-container>
						<fo:table table-layout="fixed" width="100%" font-size="24pt" line-height="1">
							<fo:table-column column-width="59.5mm"/>
							<fo:table-column column-width="67.5mm"/>
							<fo:table-column column-width="45.5mm"/>
							<fo:table-body>
								<fo:table-row>
									<fo:table-cell>
										<fo:block font-size="18pt">
											<!-- if there is iteration number, then print it -->
											<xsl:variable name="iteration" select="number(/*/ns:bibdata/ns:status/ns:iteration)"/>
											<xsl:if test="number($iteration) = $iteration">
												<xsl:text> </xsl:text>
												<xsl:value-of select="$iteration"/>
											</xsl:if>
										</fo:block>
									</fo:table-cell>
									<fo:table-cell>
										<fo:block text-align="left">
											<xsl:value-of select="$doctype_uppercased"/>
										</fo:block>
									</fo:table-cell>
									<fo:table-cell>
										<fo:block text-align="right" font-weight="bold" margin-bottom="13mm">
											<xsl:value-of select="$docidentifierISO"/>
										</fo:block>
									</fo:table-cell>
								</fo:table-row>
								<fo:table-row height="42mm">
									<fo:table-cell number-columns-spanned="3" font-size="10pt" line-height="1.2">
										<fo:block text-align="right">
											<xsl:call-template name="printEdition"/>
											<xsl:value-of select="$linebreak"/>
											<xsl:choose>
												<xsl:when test="/*/ns:bibdata/ns:date[@type = 'published']">
													<xsl:value-of select="/*/ns:bibdata/ns:date[@type = 'published']"/>
												</xsl:when>
												<xsl:when test="/*/ns:bibdata/ns:date[@type = 'created']">
													<xsl:value-of select="/*/ns:bibdata/ns:date[@type = 'created']"/>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="substring(/*/ns:bibdata/ns:version/ns:revision-date,1, 7)"/>
												</xsl:otherwise>
											</xsl:choose>
										</fo:block>
									</fo:table-cell>
								</fo:table-row>
							</fo:table-body>
						</fo:table>
						<fo:table table-layout="fixed" width="100%">
							<fo:table-column column-width="52mm"/>
							<fo:table-column column-width="7.5mm"/>
							<fo:table-column column-width="112.5mm"/>
							<fo:table-body>
								<fo:table-row>
									<fo:table-cell font-size="11pt">
										<fo:block/>
									</fo:table-cell>
									<fo:table-cell>
										<fo:block> </fo:block>
									</fo:table-cell>
									<fo:table-cell>
										<fo:block-container border-top="1mm double black" line-height="1.1">
											<fo:block margin-right="5mm">
												<fo:block font-size="18pt" font-weight="bold" margin-top="12pt">
													<xsl:if test="normalize-space($title-intro) != ''">
														<xsl:value-of select="$title-intro"/>
														<xsl:text> — </xsl:text>
													</xsl:if>
													<xsl:value-of select="$title-main"/>
													<xsl:call-template name="printTitlePartEn"/>
												</fo:block>
												<fo:block font-size="9pt">
													<xsl:value-of select="$linebreak"/>
												</fo:block>
												<fo:block font-size="11pt" font-style="italic" line-height="1.5">
													<xsl:if test="normalize-space($title-intro-fr) != ''">
														<xsl:value-of select="$title-intro-fr"/>
														<xsl:text> — </xsl:text>
													</xsl:if>
													<xsl:value-of select="$title-main-fr"/>
													<xsl:call-template name="printTitlePartFr"/>
												</fo:block>
											</fo:block>
										</fo:block-container>
									</fo:table-cell>
								</fo:table-row>
							</fo:table-body>
						</fo:table>
					</fo:block-container>
				</fo:flow>
			</fo:page-sequence>
			<fo:page-sequence master-reference="preface" format="i" force-page-count="end-on-even">
				<xsl:call-template name="insertHeaderFooter">
					<xsl:with-param name="font-weight">normal</xsl:with-param>
				</xsl:call-template>
				<fo:flow flow-name="xsl-region-body" line-height="115%">
					<xsl:if test="/*/ns:boilerplate/ns:copyright-statement">
						<fo:block-container height="252mm" display-align="after">
							<fo:block line-height="90%">
								<fo:block font-size="9pt" text-align="justify">
									<xsl:apply-templates select="/*/ns:boilerplate/ns:copyright-statement"/>
								</fo:block>
							</fo:block>
						</fo:block-container>
						<fo:block break-after="page"/>
					</xsl:if>
					<fo:block-container font-weight="bold">
						<fo:block text-align-last="justify" font-size="16pt" margin-top="10pt" margin-bottom="18pt">
							<fo:inline font-size="16pt" font-weight="bold">
								<!-- Contents -->
								<xsl:call-template name="getLocalizedString">
									<xsl:with-param name="key">table_of_contents</xsl:with-param>
								</xsl:call-template>
							</fo:inline>
							<fo:inline keep-together.within-line="always">
								<fo:leader leader-pattern="space"/>
								<fo:inline font-weight="normal" font-size="10pt">
									<!-- Page -->
									<xsl:call-template name="getLocalizedString">
										<xsl:with-param name="key">locality.page</xsl:with-param>
									</xsl:call-template>
								</fo:inline>
							</fo:inline>
						</fo:block>
						<xsl:if test="$debug = 'true'">
							<xsl:text disable-output-escaping="yes">&lt;!--</xsl:text>
								DEBUG
								contents=<xsl:copy-of select="xalan:nodeset($contents)"/>
							<xsl:text disable-output-escaping="yes">--&gt;</xsl:text>
						</xsl:if>
						<xsl:variable name="margin-left">12</xsl:variable>
						<xsl:for-each select="xalan:nodeset($contents)//item[@display = 'true']">
							<fo:block>
								<xsl:if test="@level = 1">
									<xsl:attribute name="margin-top">5pt</xsl:attribute>
								</xsl:if>
								<xsl:if test="@level = 3">
									<xsl:attribute name="margin-top">-0.7pt</xsl:attribute>
								</xsl:if>
								<fo:list-block>
									<xsl:attribute name="margin-left">
										<xsl:value-of select="$margin-left * (@level - 1)"/>mm</xsl:attribute>
									<xsl:if test="@level &gt;= 2 or @type = 'annex'">
										<xsl:attribute name="font-weight">normal</xsl:attribute>
									</xsl:if>
									<xsl:attribute name="provisional-distance-between-starts">
										<xsl:choose>
											<!-- skip 0 section without subsections -->
											<xsl:when test="@level &gt;= 3">
												<xsl:value-of select="$margin-left * 1.2"/>mm</xsl:when>
											<xsl:when test="@section != ''">
												<xsl:value-of select="$margin-left"/>mm</xsl:when>
											<xsl:otherwise>0mm</xsl:otherwise>
										</xsl:choose>
									</xsl:attribute>
									<fo:list-item>
										<fo:list-item-label end-indent="label-end()">
											<fo:block>
												<xsl:value-of select="@section"/>
											</fo:block>
										</fo:list-item-label>
										<fo:list-item-body start-indent="body-start()">
											<fo:block text-align-last="justify" margin-left="12mm" text-indent="-12mm">
												<fo:basic-link internal-destination="{@id}" fox:alt-text="{title}">
													<xsl:apply-templates select="title"/>
													<fo:inline keep-together.within-line="always">
														<fo:leader font-size="9pt" font-weight="normal" leader-pattern="dots"/>
														<fo:inline>
															<fo:page-number-citation ref-id="{@id}"/>
														</fo:inline>
													</fo:inline>
												</fo:basic-link>
											</fo:block>
										</fo:list-item-body>
									</fo:list-item>
								</fo:list-block>
							</fo:block>
						</xsl:for-each>
					</fo:block-container>
					<!-- Foreword, Introduction -->
					<xsl:call-template name="processPrefaceSectionsDefault"/>
				</fo:flow>
			</fo:page-sequence>
			<!-- Main pages -->
			<fo:page-sequence master-reference="document" initial-page-number="1" force-page-count="no-force">
				<fo:static-content flow-name="xsl-footnote-separator">
					<fo:block>
						<fo:leader leader-pattern="rule" leader-length="30%"/>
					</fo:block>
				</fo:static-content>
				<xsl:call-template name="insertHeaderFooter"/>
				<fo:flow flow-name="xsl-region-body">
					<fo:block-container>
						<fo:block font-size="18pt" font-weight="bold" margin-top="40pt" margin-bottom="20pt" line-height="1.1">
							<xsl:variable name="title-part-doc-lang" select="/*/ns:bibdata/ns:title[@language = $lang and @type = 'title-part']"/>
							<xsl:variable name="title-intro-doc-lang" select="/*/ns:bibdata/ns:title[@language = $lang and @type = 'title-intro']"/>
							<fo:block>
								<xsl:if test="normalize-space($title-intro-doc-lang) != ''">
									<xsl:value-of select="$title-intro-doc-lang"/>
									<xsl:text> — </xsl:text>
								</xsl:if>
								<xsl:variable name="title-main-doc-lang" select="/*/ns:bibdata/ns:title[@language = $lang and @type = 'title-main']"/>
								<xsl:value-of select="$title-main-doc-lang"/>
								<xsl:if test="normalize-space($title-part-doc-lang) != ''">
									<xsl:if test="$part != ''">
										<xsl:text> — </xsl:text>
										<fo:block font-weight="normal" margin-top="12pt" line-height="1.1">
											<xsl:value-of select="java:replaceAll(java:java.lang.String.new($titles/title-part[@lang=$lang]),'#',$part)"/>
										</fo:block>
									</xsl:if>
								</xsl:if>
							</fo:block>
							<fo:block>
								<xsl:value-of select="$title-part-doc-lang"/>
							</fo:block>
						</fo:block>
					</fo:block-container>
					<fo:block>
						<xsl:call-template name="processMainSectionsDefault"/>
						<fo:block id="lastBlock" font-size="1pt"> </fo:block>
					</fo:block>
				</fo:flow>
			</fo:page-sequence>
			<!-- Index -->
			<xsl:apply-templates select="//ns:indexsect" mode="index"/>
			<!-- last page -->
			<fo:page-sequence master-reference="last-page" force-page-count="no-force">
				<xsl:call-template name="insertHeaderEven"/>
				<fo:static-content flow-name="last-page-footer" font-size="10pt">
					<fo:table table-layout="fixed" width="100%">
						<fo:table-column column-width="33%"/>
						<fo:table-column column-width="33%"/>
						<fo:table-column column-width="34%"/>
						<fo:table-body>
							<fo:table-row>
								<fo:table-cell display-align="center">
									<fo:block font-size="9pt">
										<xsl:value-of select="$copyrightText"/>
									</fo:block>
								</fo:table-cell>
								<fo:table-cell>
									<fo:block font-size="11pt" font-weight="bold" text-align="center">
									</fo:block>
								</fo:table-cell>
								<fo:table-cell>
									<fo:block> </fo:block>
								</fo:table-cell>
							</fo:table-row>
						</fo:table-body>
					</fo:table>
				</fo:static-content>
				<fo:flow flow-name="xsl-region-body">
					<fo:block-container height="252mm" display-align="after">
						<fo:block-container border-top="1mm double black">
							<fo:block font-size="12pt" font-weight="bold" padding-top="3.5mm" padding-bottom="0.5mm">
								<xsl:for-each select="/*/ns:bibdata/ns:ext/ns:ics/ns:code">
									<xsl:if test="position() = 1">
										<fo:inline>ICS  </fo:inline>
									</xsl:if>
									<xsl:value-of select="."/>
									<xsl:if test="position() != last()">
										<xsl:text>; </xsl:text>
									</xsl:if>
								</xsl:for-each> 
							</fo:block>
							<xsl:if test="/*/ns:bibdata/ns:keyword">
								<fo:block font-size="9pt" margin-bottom="6pt">
									<xsl:variable name="title-descriptors">
										<xsl:call-template name="getTitle">
											<xsl:with-param name="name" select="'title-descriptors'"/>
										</xsl:call-template>
									</xsl:variable>
									<fo:inline font-weight="bold">
										<xsl:value-of select="$title-descriptors"/>: </fo:inline>
									<xsl:call-template name="insertKeywords">
										<xsl:with-param name="sorting">no</xsl:with-param>
									</xsl:call-template>
								</fo:block>
							</xsl:if>
							<xsl:variable name="countPages"/>
							<xsl:variable name="price_based_on">
								<xsl:call-template name="getLocalizedString">
									<xsl:with-param name="key">price_based_on</xsl:with-param>
								</xsl:call-template>
							</xsl:variable>
							<xsl:variable name="price_based_on_items">
								<xsl:call-template name="split">
									<xsl:with-param name="pText" select="$price_based_on"/>
									<xsl:with-param name="sep" select="'%'"/>
									<xsl:with-param name="normalize-space">false</xsl:with-param>
								</xsl:call-template>
							</xsl:variable>
							<!-- Price based on ... pages -->
							<fo:block font-size="9pt">
								<xsl:for-each select="xalan:nodeset($price_based_on_items)/item">
									<xsl:value-of select="."/>
									<xsl:if test="position() != last()">
										<fo:page-number-citation ref-id="lastBlock"/>
									</xsl:if>
								</xsl:for-each>
							</fo:block>
						</fo:block-container>
					</fo:block-container>
				</fo:flow>
			</fo:page-sequence>
		</fo:root>
	</xsl:template>

	<xsl:template match="node()">
		<xsl:apply-templates/>
	</xsl:template>

	<!-- ============================= -->
	<!-- CONTENTS                      -->
	<!-- ============================= -->
	<xsl:template match="node()" mode="contents">
		<xsl:apply-templates mode="contents"/>
	</xsl:template>

	<!-- element with title -->
	<xsl:template match="*[ns:title]" mode="contents">
		<xsl:variable name="level">
			<xsl:call-template name="getLevel">
				<xsl:with-param name="depth" select="ns:title/@depth"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="section">
			<xsl:call-template name="getSection"/>
		</xsl:variable>
		<xsl:variable name="type">
			<xsl:choose>
				<xsl:when test="local-name() = 'indexsect'">index</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="local-name()"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="display">
			<xsl:choose>
				<xsl:when test="ancestor-or-self::ns:annex and $level &gt;= 2">false</xsl:when>
				<xsl:when test="$section = '' and $type = 'clause'">false</xsl:when>
				<xsl:when test="$level &lt;= 3">true</xsl:when>
				<xsl:otherwise>false</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="skip">
			<xsl:choose>
				<xsl:when test="ancestor-or-self::ns:bibitem">true</xsl:when>
				<xsl:when test="ancestor-or-self::ns:term">true</xsl:when>
				<xsl:otherwise>false</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="$skip = 'false'">
			<xsl:variable name="title">
				<xsl:call-template name="getName"/>
			</xsl:variable>
			<xsl:variable name="root">
				<xsl:if test="ancestor-or-self::ns:preface">preface</xsl:if>
				<xsl:if test="ancestor-or-self::ns:annex">annex</xsl:if>
			</xsl:variable>
			<item id="{@id}" level="{$level}" section="{$section}" type="{$type}" root="{$root}" display="{$display}">
				<xsl:if test="$type = 'index'">
					<xsl:attribute name="level">1</xsl:attribute>
				</xsl:if>
				<title>
					<xsl:apply-templates select="xalan:nodeset($title)" mode="contents_item"/>
				</title>
				<xsl:if test="$type != 'index'">
					<xsl:apply-templates mode="contents"/>
				</xsl:if>
			</item>
		</xsl:if>
	</xsl:template>

	<xsl:template match="ns:p | ns:termsource | ns:termnote" mode="contents"/>
	<xsl:template match="ns:references/ns:bibitem" mode="contents"/>
	
	<xsl:template name="processPrefaceSectionsDefault_Contents">
		<xsl:apply-templates select="/*/ns:preface/ns:abstract" mode="contents"/>
		<xsl:apply-templates select="/*/ns:preface/ns:foreword" mode="contents"/>
		<xsl:apply-templates select="/*/ns:preface/ns:introduction" mode="contents"/>
		<xsl:apply-templates select="/*/ns:preface/*[local-name() != 'abstract' and local-name() != 'foreword' and local-name() != 'introduction' and local-name() != 'acknowledgements']" mode="contents"/>
		<xsl:apply-templates select="/*/ns:preface/ns:acknowledgements" mode="contents"/>
	</xsl:template>

	<xsl:template name="processMainSectionsDefault_Contents">
		<xsl:apply-templates select="/*/ns:sections/ns:clause[@type='scope']" mode="contents"/>
		<!-- Normative references  -->
		<xsl:apply-templates select="/*/ns:bibliography/ns:references[@normative='true'] |   /*/ns:bibliography/ns:clause[ns:references[@normative='true']]" mode="contents"/>
		<!-- Terms and definitions -->
		<xsl:apply-templates select="/*/ns:sections/ns:terms |
		/*/ns:sections/ns:clause[.//ns:terms] |
		/*/ns:sections/ns:definitions |
		/*/ns:sections/ns:clause[.//ns:definitions]" mode="contents"/>
		<!-- Another main sections -->
		<xsl:apply-templates select="/*/ns:sections/*[local-name() != 'terms' and
		local-name() != 'definitions' and
		not(@type='scope') and
		not(local-name() = 'clause' and .//ns:terms) and 
		not(local-name() = 'clause' and .//ns:definitions)]" mode="contents"/>
		<xsl:apply-templates select="/*/ns:annex" mode="contents"/>
		<!-- Bibliography -->
		<xsl:apply-templates select="/*/ns:bibliography/ns:references[not(@normative='true')] |
		/*/ns:bibliography/ns:clause[ns:references[not(@normative='true')]]" mode="contents"/>
	</xsl:template>
	
	<xsl:template match="ns:figure/ns:name |
	ns:table/ns:name |
	ns:permission/ns:name |
	ns:recommendation/ns:name |
	ns:requirement/ns:name" mode="contents">
		<xsl:apply-templates mode="contents"/>
		<xsl:text> </xsl:text>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'figure' or local-name() = 'table' or local-name() = 'permission' or local-name() = 'recommendation' or local-name() = 'requirement']/ns:name/text()" mode="contents" priority="2">
		<xsl:value-of select="."/>
	</xsl:template>
	
	<xsl:template match="node()" mode="contents">
		<xsl:apply-templates mode="contents"/>
	</xsl:template>
	
	<xsl:template match="*[local-name() = 'title' or local-name() = 'name']//ns:stem" mode="contents">
		<xsl:apply-templates select="."/>
	</xsl:template>
	
	<xsl:template match="ns:references[@hidden='true']" mode="contents" priority="3"/>

	<xsl:template match="ns:fn" mode="contents"/>
	
	<xsl:template match="ns:fn" mode="contents_item"/>
	<xsl:template match="ns:tab" mode="contents_item">
		<xsl:text> </xsl:text>
	</xsl:template>

	<xsl:template match="ns:strong" mode="contents_item">
		<xsl:copy>
			<xsl:apply-templates mode="contents_item"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="ns:em" mode="contents_item">
		<xsl:copy>
			<xsl:apply-templates mode="contents_item"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="ns:stem" mode="contents_item">
		<xsl:copy-of select="."/>
	</xsl:template>

	<xsl:template match="ns:br" mode="contents_item">
		<xsl:text> </xsl:text>
	</xsl:template>
	
	<xsl:template match="ns:title" mode="contents_item">
		<xsl:apply-templates mode="contents_item"/>
	</xsl:template>
	
	<!-- ============================= -->
	<!-- END CONTENTS                      -->
	<!-- ============================= -->
	
	
	<xsl:template match="ns:license-statement//ns:title">
		<fo:block text-align="center" font-weight="bold">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:license-statement//ns:p">
		<fo:block margin-left="1.5mm" margin-right="1.5mm">
			<xsl:if test="following-sibling::ns:p">
				<xsl:attribute name="margin-top">6pt</xsl:attribute>
				<xsl:attribute name="margin-bottom">6pt</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<!-- <fo:block margin-bottom="12pt">© ISO 2019, Published in Switzerland.</fo:block>
			<fo:block font-size="10pt" margin-bottom="12pt">All rights reserved. Unless otherwise specified, no part of this publication may be reproduced or utilized otherwise in any form or by any means, electronic or mechanical, including photocopying, or posting on the internet or an intranet, without prior written permission. Permission can be requested from either ISO at the address below or ISO’s member body in the country of the requester.</fo:block>
			<fo:block font-size="10pt" text-indent="7.1mm">
				<fo:block>ISO copyright office</fo:block>
				<fo:block>Ch. de Blandonnet 8 • CP 401</fo:block>
				<fo:block>CH-1214 Vernier, Geneva, Switzerland</fo:block>
				<fo:block>Tel.  + 41 22 749 01 11</fo:block>
				<fo:block>Fax  + 41 22 749 09 47</fo:block>
				<fo:block>copyright@iso.org</fo:block>
				<fo:block>www.iso.org</fo:block>
			</fo:block> -->
	<xsl:template match="ns:copyright-statement/ns:clause[1]/ns:title">
		<fo:block margin-bottom="3mm">
			<fo:external-graphic src="{concat('data:image/png;base64,', normalize-space($Image-Attention))}" width="14mm" content-height="13mm" content-width="scale-to-fit" scaling="uniform" fox:alt-text="Image {@alt}"/>
			<fo:inline padding-left="6mm" font-size="12pt" font-weight="bold">
				<xsl:apply-templates/>
			</fo:inline>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:copyright-statement//ns:p">
		<fo:block>
			<xsl:if test="preceding-sibling::ns:p">
			</xsl:if>
			<xsl:if test="following-sibling::ns:p">
				<xsl:attribute name="margin-bottom">3pt</xsl:attribute>
			</xsl:if>
			<xsl:if test="contains(@id, 'address')">
				<xsl:attribute name="margin-left">4mm</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<!-- ====== -->
	<!-- Title     -->
	<!-- ====== -->
	<xsl:template match="ns:annex/ns:title">
		<fo:block font-size="16pt" text-align="center" margin-bottom="48pt" keep-with-next="always">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<!-- Bibliography -->
	<xsl:template match="ns:references[not(@normative='true')]/ns:title">
		<fo:block font-size="16pt" font-weight="bold" text-align="center" margin-top="6pt" margin-bottom="36pt" keep-with-next="always">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:title">
		<xsl:variable name="level">
			<xsl:call-template name="getLevel"/>
		</xsl:variable>
		<xsl:variable name="font-size">
			<xsl:choose>
				<xsl:when test="ancestor::ns:annex and $level = 2">13pt</xsl:when>
				<xsl:when test="ancestor::ns:annex and $level = 3">12pt</xsl:when>
				<xsl:when test="ancestor::ns:preface">16pt</xsl:when>
				<xsl:when test="$level = 2">12pt</xsl:when>
				<xsl:when test="$level &gt;= 3">11pt</xsl:when>
				<xsl:otherwise>13pt</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="element-name">
			<xsl:choose>
				<xsl:when test="../@inline-header = 'true'">fo:inline</xsl:when>
				<xsl:otherwise>fo:block</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$doctype = 'amendment' and not(ancestor::ns:preface)">
				<fo:block font-size="11pt" font-style="italic" margin-bottom="12pt" keep-with-next="always">
					<xsl:apply-templates/>
				</fo:block>
			</xsl:when>
			<xsl:otherwise>
				<xsl:element name="{$element-name}">
					<xsl:attribute name="font-size">
						<xsl:value-of select="$font-size"/>
					</xsl:attribute>
					<xsl:attribute name="font-weight">bold</xsl:attribute>
					<xsl:attribute name="margin-top">
						<xsl:choose>
							<xsl:when test="ancestor::ns:preface">8pt</xsl:when>
							<xsl:when test="$level = 2 and ancestor::ns:annex">18pt</xsl:when>
							<xsl:when test="$level = 1">18pt</xsl:when>
							<xsl:when test="$level &gt;= 3">3pt</xsl:when>
							<xsl:when test="$level = ''">6pt</xsl:when>
							<xsl:otherwise>12pt</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					<xsl:attribute name="margin-bottom">
						<xsl:choose>
							<xsl:when test="ancestor::ns:preface">18pt</xsl:when>
							<xsl:otherwise>8pt</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					<xsl:attribute name="keep-with-next">always</xsl:attribute>
					<xsl:if test="$element-name = 'fo:inline'">
						<xsl:attribute name="padding-right">2mm</xsl:attribute>
					</xsl:if>
					<xsl:apply-templates/>
				</xsl:element>
				<xsl:if test="$element-name = 'fo:inline' and not(following-sibling::ns:p)">
					<fo:block>
						<xsl:value-of select="$linebreak"/>
					</fo:block>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- ====== -->
	<!-- End Title -->
	<!-- ====== -->
	
	<xsl:template match="ns:p">
		<xsl:param name="inline" select="'false'"/>
		<xsl:variable name="previous-element" select="local-name(preceding-sibling::*[1])"/>
		<xsl:variable name="element-name">
			<xsl:choose>
				<xsl:when test="$inline = 'true'">fo:inline</xsl:when>
				<xsl:when test="../@inline-header = 'true' and $previous-element = 'title'">fo:inline</xsl:when>
				<!-- first paragraph after inline title -->
				<xsl:when test="local-name(..) = 'admonition'">fo:inline</xsl:when>
				<xsl:otherwise>fo:block</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:element name="{$element-name}">
			<xsl:attribute name="text-align">
				<xsl:choose>
					<xsl:when test="@align">
						<xsl:value-of select="@align"/>
					</xsl:when>
					<xsl:when test="ancestor::ns:td/@align">
						<xsl:value-of select="ancestor::ns:td/@align"/>
					</xsl:when>
					<xsl:when test="ancestor::ns:th/@align">
						<xsl:value-of select="ancestor::ns:th/@align"/>
					</xsl:when>
					<xsl:otherwise>justify</xsl:otherwise>
					<!-- default alignment-->
				</xsl:choose>
			</xsl:attribute>
			<xsl:attribute name="margin-bottom">8pt</xsl:attribute>
			<xsl:if test="@id">
				<xsl:attribute name="id">
					<xsl:value-of select="@id"/>
				</xsl:attribute>
			</xsl:if>
			<!-- bookmarks only in paragraph -->
			<xsl:if test="count(ns:bookmark) != 0 and count(*) = count(ns:bookmark) and normalize-space() = ''">
				<xsl:attribute name="font-size">0</xsl:attribute>
				<xsl:attribute name="margin-bottom">0pt</xsl:attribute>
				<xsl:attribute name="line-height">0</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates/>
		</xsl:element>
		<xsl:if test="$element-name = 'fo:inline' and not($inline = 'true') and not(local-name(..) = 'admonition')">
			<fo:block margin-bottom="12pt">
				<xsl:if test="ancestor::ns:annex or following-sibling::ns:table">
					<xsl:attribute name="margin-bottom">0</xsl:attribute>
				</xsl:if>
				<xsl:value-of select="$linebreak"/>
			</fo:block>
		</xsl:if>
		<xsl:if test="$inline = 'true'">
			<fo:block> </fo:block>
		</xsl:if>
	</xsl:template>

	<xsl:template match="ns:li//ns:p//text()">
		<xsl:choose>
			<xsl:when test="contains(., '&#9;')">
				<fo:inline white-space="pre">
					<xsl:value-of select="."/>
				</fo:inline>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="."/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- Example of source xml:
	<fn reference="1">
			<p id="_8e5cf917-f75a-4a49-b0aa-1714cb6cf954">Formerly denoted as 15 % (m/m).</p>
		</fn>
	-->
	<xsl:variable name="p_fn">
		<xsl:for-each select="//ns:p/ns:fn[generate-id(.)=generate-id(key('kfn',@reference)[1])]">
			<!-- copy unique fn -->
			<fn gen_id="{generate-id(.)}">
				<xsl:copy-of select="@*"/>
				<xsl:copy-of select="node()"/>
			</fn>
		</xsl:for-each>
	</xsl:variable>
	<xsl:template match="ns:p/ns:fn" priority="2">
		<xsl:variable name="gen_id" select="generate-id(.)"/>
		<xsl:variable name="reference" select="@reference"/>
		<xsl:variable name="number">
			<xsl:value-of select="count(xalan:nodeset($p_fn)//fn[@reference = $reference]/preceding-sibling::fn) + 1"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="xalan:nodeset($p_fn)//fn[@gen_id = $gen_id]">
				<fo:footnote>
					<fo:inline font-size="80%" keep-with-previous.within-line="always" vertical-align="super">
						<fo:basic-link internal-destination="footnote_{@reference}_{$number}" fox:alt-text="footnote {@reference} {$number}">
							<xsl:value-of select="$number + count(//ns:bibitem[ancestor::ns:references[@normative='true']]/ns:note)"/>
							<xsl:text>)</xsl:text>
						</fo:basic-link>
					</fo:inline>
					<fo:footnote-body>
						<fo:block font-size="10pt" margin-bottom="12pt">
							<fo:inline id="footnote_{@reference}_{$number}" keep-with-next.within-line="always" padding-right="3mm">
								<xsl:value-of select="$number + count(//ns:bibitem[ancestor::ns:references[@normative='true']]/ns:note)"/>
								<xsl:text>)</xsl:text>
							</fo:inline>
							<xsl:for-each select="ns:p">
								<xsl:apply-templates/>
							</xsl:for-each>
						</fo:block>
					</fo:footnote-body>
				</fo:footnote>
			</xsl:when>
			<xsl:otherwise>
				<fo:inline font-size="60%" keep-with-previous.within-line="always" vertical-align="super">
					<fo:basic-link internal-destination="footnote_{@reference}_{$number}" fox:alt-text="footnote {@reference} {$number}">
						<xsl:value-of select="$number + count(//ns:bibitem/ns:note)"/>
					</fo:basic-link>
				</fo:inline>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="ns:p/ns:fn/ns:p">
		<xsl:apply-templates/>
	</xsl:template>

	
	<xsl:template match="ns:note" mode="process">
		<xsl:call-template name="note"/>
	</xsl:template>

	<xsl:template match="*" mode="process">
		<xsl:apply-templates select="."/>
	</xsl:template>

	

	<xsl:template match="ns:admonition">
		<fo:block margin-bottom="12pt" font-weight="bold">
			<xsl:variable name="type">
				<xsl:call-template name="getLocalizedString">
					<xsl:with-param name="key">admonition.<xsl:value-of select="@type"/>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:variable>
			<xsl:value-of select="java:toUpperCase(java:java.lang.String.new($type))"/>
			<xsl:text> — </xsl:text>
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	
	<!-- Example for PDF attachments -->
	<xsl:template match="ns:eref[contains(@bibitemid, '.exp')]" priority="2">
		<fo:inline xsl:use-attribute-sets="eref-style">
			<xsl:variable name="url" select="concat('url(embedded-file:', @bibitemid, ')')"/>
			<fo:basic-link external-destination="{$url}" fox:alt-text="{@citeas}">
				<xsl:if test="normalize-space(@citeas) = ''">
					<xsl:attribute name="fox:alt-text">
						<xsl:value-of select="."/>
					</xsl:attribute>
				</xsl:if>
				<xsl:apply-templates/>
			</fo:basic-link>
		</fo:inline>
	</xsl:template>

	
	<xsl:template match="ns:xref" priority="2">
		<fo:basic-link internal-destination="{@target}" fox:alt-text="{@target}" xsl:use-attribute-sets="xref-style">
			<xsl:choose>
				<xsl:when test="@pagenumber='true'">
					<fo:inline>
						<xsl:if test="@id">
							<xsl:attribute name="id">
								<xsl:value-of select="@id"/>
							</xsl:attribute>
						</xsl:if>
						<fo:page-number-citation ref-id="{@target}"/>
					</fo:inline>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates/>
				</xsl:otherwise>
			</xsl:choose>
		</fo:basic-link>
	</xsl:template>

	
	<xsl:template name="insertHeaderFooter">
		<xsl:param name="font-weight" select="'bold'"/>
		<xsl:call-template name="insertHeaderEven"/>
		<fo:static-content flow-name="footer-even">
			<fo:block-container>
				<fo:table table-layout="fixed" width="100%">
					<fo:table-column column-width="33%"/>
					<fo:table-column column-width="33%"/>
					<fo:table-column column-width="34%"/>
					<fo:table-body>
						<fo:table-row>
							<fo:table-cell display-align="center" padding-top="0mm" font-size="11pt" font-weight="{$font-weight}">
								<fo:block>
									<fo:page-number/>
								</fo:block>
							</fo:table-cell>
							<fo:table-cell display-align="center">
								<fo:block font-size="11pt" font-weight="bold" text-align="center">
									
								</fo:block>
							</fo:table-cell>
							<fo:table-cell display-align="center" padding-top="0mm" font-size="9pt">
								<fo:block text-align="right">
									<xsl:value-of select="$copyrightText"/>
								</fo:block>
							</fo:table-cell>
						</fo:table-row>
					</fo:table-body>
				</fo:table>
			</fo:block-container>
		</fo:static-content>
		<fo:static-content flow-name="header-first">
			<fo:block-container margin-top="13mm" height="9mm" width="172mm" border-top="0.5mm solid black" border-bottom="0.5mm solid black" display-align="center" background-color="white">
				<fo:block text-align-last="justify" font-size="12pt" font-weight="bold">
					<xsl:value-of select="$stage-fullname-uppercased"/>
					<fo:inline keep-together.within-line="always">
						<fo:leader leader-pattern="space"/>
						<fo:inline>
							<xsl:value-of select="$ISOname"/>
						</fo:inline>
					</fo:inline>
				</fo:block>
			</fo:block-container>
		</fo:static-content>
		<fo:static-content flow-name="header-odd">
			<fo:block-container height="24mm" display-align="before">
				<fo:block font-size="12pt" font-weight="bold" text-align="right" padding-top="12.5mm">
					<xsl:value-of select="$ISOname"/>
				</fo:block>
			</fo:block-container>
		</fo:static-content>
		<fo:static-content flow-name="footer-odd">
			<fo:block-container>
				<fo:table table-layout="fixed" width="100%">
					<fo:table-column column-width="33%"/>
					<fo:table-column column-width="33%"/>
					<fo:table-column column-width="34%"/>
					<fo:table-body>
						<fo:table-row>
							<fo:table-cell display-align="center" padding-top="0mm" font-size="9pt">
								<fo:block>
									<xsl:value-of select="$copyrightText"/>
								</fo:block>
							</fo:table-cell>
							<fo:table-cell display-align="center">
								<fo:block font-size="11pt" font-weight="bold" text-align="center">
									
								</fo:block>
							</fo:table-cell>
							<fo:table-cell display-align="center" padding-top="0mm" font-size="11pt" font-weight="{$font-weight}">
								<fo:block text-align="right">
									<fo:page-number/>
								</fo:block>
							</fo:table-cell>
						</fo:table-row>
					</fo:table-body>
				</fo:table>
			</fo:block-container>
		</fo:static-content>
	</xsl:template>

	<xsl:template name="insertHeaderEven">
		<fo:static-content flow-name="header-even">
			<fo:block-container height="24mm" display-align="before">
				<fo:block font-size="12pt" font-weight="bold" padding-top="12.5mm">
					<xsl:value-of select="$ISOname"/>
				</fo:block>
			</fo:block-container>
		</fo:static-content>
	</xsl:template>

	<xsl:variable name="Image-ISO-Logo">
		<xsl:text>iVBORw0KGgoAAAANSUhEUgAAAPcAAADiCAYAAACSl1F7AAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAABT9pVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuNi1jMDE0IDc5LjE1Njc5NywgMjAxNC8wOC8yMC0wOTo1MzowMiAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wUmlnaHRzPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvcmlnaHRzLyIgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIgeG1wUmlnaHRzOk1hcmtlZD0iVHJ1ZSIgeG1wUmlnaHRzOldlYlN0YXRlbWVudD0iaHR0cDovL3d3dy5pc28ub3JnL2lzby9ob21lL3BvbGljaWVzLmh0bSIgeG1wTU06T3JpZ2luYWxEb2N1bWVudElEPSJ4bXAuZGlkOjNjZGZlYTk5LWYzY2QtNDcyYS1hNGVmLWQ4ZmY5MDQ4YTk0NSIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDozRjU0RkYwNTc5OTIxMUVBQjEyNkEyOUU0MUE2ODdFNCIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDozRjU0RkYwNDc5OTIxMUVBQjEyNkEyOUU0MUE2ODdFNCIgeG1wOkNyZWF0b3JU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</xsl:text>
	</xsl:variable>
	<xsl:variable name="Image-Attention">
		<xsl:text>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</xsl:text>
	</xsl:variable>
	
	

	<!-- ============================== -->
	<!-- Titles -->
	<!-- ============================== -->
	<xsl:variable name="titles" select="xalan:nodeset($titles_)"/>
	<xsl:variable name="titles_">
		<title-annex lang="en">Annex </title-annex>
		<title-annex lang="fr">Annexe </title-annex>
		<title-annex lang="zh">Annex </title-annex>
		<title-edition lang="en">
			<xsl:text>Edition </xsl:text>
		</title-edition>
		<title-edition lang="fr">
			<xsl:text>Édition </xsl:text>
		</title-edition>
		<title-toc lang="en">
			<xsl:text>Contents</xsl:text>
		</title-toc>
		<title-toc lang="fr">
			<xsl:text>Sommaire</xsl:text>
		</title-toc>
		<title-toc lang="zh">Contents</title-toc>
		<title-page lang="en">Page</title-page>
		<title-page lang="fr">Page</title-page>
		<title-key lang="en">Key</title-key>
		<title-key lang="fr">Légende</title-key>
		<title-where lang="en">where</title-where>
		<title-where lang="fr">où</title-where>
		<title-descriptors lang="en">Descriptors</title-descriptors>
		<title-part lang="en">
			<xsl:text>Part #:</xsl:text>
		</title-part>
		<title-part lang="fr">
			<xsl:text>Partie #:</xsl:text>
		</title-part>
		<title-part lang="zh">第 # 部分:</title-part>
		<title-subpart lang="en">			
			
		</title-subpart>
		<title-subpart lang="fr">		
			
		</title-subpart>
		<title-modified lang="en">modified</title-modified>
		<title-modified lang="fr">modifiée</title-modified>
		<title-modified lang="zh">modified</title-modified>
		<title-source lang="en">
			<xsl:text>SOURCE</xsl:text>
		</title-source>
		<title-keywords lang="en">Keywords</title-keywords>
		<title-deprecated lang="en">DEPRECATED</title-deprecated>
		<title-deprecated lang="fr">DEPRECATED</title-deprecated>
		<title-list-tables lang="en">List of Tables</title-list-tables>
		<title-list-figures lang="en">List of Figures</title-list-figures>
		<title-list-recommendations lang="en">List of Recommendations</title-list-recommendations>
		<title-acknowledgements lang="en">Acknowledgements</title-acknowledgements>
		<title-abstract lang="en">Abstract</title-abstract>
		<title-summary lang="en">Summary</title-summary>
		<title-in lang="en">in </title-in>
		<title-partly-supercedes lang="en">Partly Supercedes </title-partly-supercedes>
		<title-partly-supercedes lang="zh">部分代替 </title-partly-supercedes>
		<title-completion-date lang="en">Completion date for this manuscript</title-completion-date>
		<title-completion-date lang="zh">本稿完成日期</title-completion-date>
		<title-issuance-date lang="en">Issuance Date: #</title-issuance-date>
		<title-issuance-date lang="zh"># 发布</title-issuance-date>
		<title-implementation-date lang="en">Implementation Date: #</title-implementation-date>
		<title-implementation-date lang="zh"># 实施</title-implementation-date>
		<title-obligation-normative lang="en">normative</title-obligation-normative>
		<title-obligation-normative lang="zh">规范性附录</title-obligation-normative>
		<title-caution lang="en">CAUTION</title-caution>
		<title-caution lang="zh">注意</title-caution>
		<title-warning lang="en">WARNING</title-warning>
		<title-warning lang="zh">警告</title-warning>
		<title-amendment lang="en">AMENDMENT</title-amendment>
		<title-continued lang="en">(continued)</title-continued>
		<title-continued lang="fr">(continué)</title-continued>
	</xsl:variable>
	
	<xsl:template name="getTitle">
		<xsl:param name="name"/>
		<xsl:param name="lang"/>
		<xsl:variable name="lang_">
			<xsl:choose>
				<xsl:when test="$lang != ''">
					<xsl:value-of select="$lang"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="getLang"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="language" select="normalize-space($lang_)"/>
		<xsl:variable name="title_" select="$titles/*[local-name() = $name][@lang = $language]"/>
		<xsl:choose>
			<xsl:when test="normalize-space($title_) != ''">
				<xsl:value-of select="$title_"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$titles/*[local-name() = $name][@lang = 'en']"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- ============================== -->
	<!-- END Titles -->
	<!-- ============================== -->

	<xsl:variable name="lower">abcdefghijklmnopqrstuvwxyz</xsl:variable>
	<xsl:variable name="upper">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>
	<xsl:variable name="en_chars" select="concat($lower,$upper,',.`1234567890-=~!@#$%^*()_+[]{}\|?/')"/>
	<xsl:variable name="linebreak" select="'&#8232;'"/>
	
	
	<!-- ================= -->
	<!-- Attribute sets -->
	<!-- ================= -->
	<xsl:attribute-set name="root-style">
		<xsl:attribute name="font-family">Times New Roman, Cambria Math, Source Han Sans</xsl:attribute>
		<xsl:attribute name="font-size">11pt</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="link-style">
		<xsl:attribute name="color">blue</xsl:attribute>
		<xsl:attribute name="text-decoration">underline</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="sourcecode-style">
		<xsl:attribute name="white-space">pre</xsl:attribute>
		<xsl:attribute name="wrap-option">wrap</xsl:attribute>
		<xsl:attribute name="font-family">Courier</xsl:attribute>
		<xsl:attribute name="margin-bottom">12pt</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="permission-style">
		
	</xsl:attribute-set>

	<xsl:attribute-set name="permission-name-style">
		
	</xsl:attribute-set>

	<xsl:attribute-set name="permission-label-style">
		
	</xsl:attribute-set>

	<xsl:attribute-set name="requirement-style">
		
	</xsl:attribute-set>

	<xsl:attribute-set name="requirement-name-style">
		
	</xsl:attribute-set>

	<xsl:attribute-set name="requirement-label-style">
		
	</xsl:attribute-set>

	<xsl:attribute-set name="requirement-subject-style">
	</xsl:attribute-set>

	<xsl:attribute-set name="requirement-inherit-style">
	</xsl:attribute-set>

	<xsl:attribute-set name="recommendation-style">
		
		
	</xsl:attribute-set>

	<xsl:attribute-set name="recommendation-name-style">
		
		
	</xsl:attribute-set>

	<xsl:attribute-set name="recommendation-label-style">
		
	</xsl:attribute-set>

	<xsl:attribute-set name="termexample-style">
		<xsl:attribute name="font-size">10pt</xsl:attribute>
		<xsl:attribute name="margin-top">8pt</xsl:attribute>
		<xsl:attribute name="margin-bottom">8pt</xsl:attribute>
		<xsl:attribute name="text-align">justify</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="example-style">
		<xsl:attribute name="font-size">10pt</xsl:attribute>
		<xsl:attribute name="margin-top">8pt</xsl:attribute>
		<xsl:attribute name="margin-bottom">8pt</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="example-body-style">
		
		
		
	</xsl:attribute-set>

	<xsl:attribute-set name="example-name-style">
		<xsl:attribute name="padding-right">5mm</xsl:attribute>
		<xsl:attribute name="keep-with-next">always</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="example-p-style">
		<xsl:attribute name="font-size">10pt</xsl:attribute>
		<xsl:attribute name="margin-top">8pt</xsl:attribute>
		<xsl:attribute name="margin-bottom">8pt</xsl:attribute>
		<xsl:attribute name="text-align">justify</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="termexample-name-style">
		<xsl:attribute name="padding-right">5mm</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="table-name-style">
		<xsl:attribute name="keep-with-next">always</xsl:attribute>
		<xsl:attribute name="font-size">11pt</xsl:attribute>
		<xsl:attribute name="font-weight">bold</xsl:attribute>
		<xsl:attribute name="text-align">center</xsl:attribute>
		<!-- <xsl:attribute name="margin-top">12pt</xsl:attribute> -->
		<xsl:attribute name="margin-bottom">6pt</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="table-footer-cell-style">
		
	</xsl:attribute-set>

	<xsl:attribute-set name="appendix-style">
		<xsl:attribute name="font-size">12pt</xsl:attribute>
		<xsl:attribute name="font-weight">bold</xsl:attribute>
		<xsl:attribute name="margin-top">12pt</xsl:attribute>
		<xsl:attribute name="margin-bottom">12pt</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="appendix-example-style">
		<xsl:attribute name="font-size">10pt</xsl:attribute>
		<xsl:attribute name="margin-top">8pt</xsl:attribute>
		<xsl:attribute name="margin-bottom">8pt</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="xref-style">
		<xsl:attribute name="color">blue</xsl:attribute>
		<xsl:attribute name="text-decoration">underline</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="eref-style">
		
	</xsl:attribute-set>

	<xsl:attribute-set name="note-style">
		<xsl:attribute name="font-size">10pt</xsl:attribute>
		<xsl:attribute name="margin-top">8pt</xsl:attribute>
		<xsl:attribute name="margin-bottom">12pt</xsl:attribute>
		<xsl:attribute name="text-align">justify</xsl:attribute>
	</xsl:attribute-set>

	<xsl:variable name="note-body-indent">10mm</xsl:variable>
	<xsl:variable name="note-body-indent-table">5mm</xsl:variable>
	<xsl:attribute-set name="note-name-style">
		<xsl:attribute name="padding-right">6mm</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="note-p-style">
		<xsl:attribute name="margin-top">8pt</xsl:attribute>
		<xsl:attribute name="margin-bottom">12pt</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="termnote-style">
		<xsl:attribute name="font-size">10pt</xsl:attribute>
		<xsl:attribute name="margin-top">8pt</xsl:attribute>
		<xsl:attribute name="margin-bottom">8pt</xsl:attribute>
		<xsl:attribute name="text-align">justify</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="termnote-name-style">		

	</xsl:attribute-set>

	<xsl:attribute-set name="quote-style">
		<xsl:attribute name="margin-top">12pt</xsl:attribute>
		<xsl:attribute name="margin-left">12mm</xsl:attribute>
		<xsl:attribute name="margin-right">12mm</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="quote-source-style">
		<xsl:attribute name="text-align">right</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="termsource-style">
		<xsl:attribute name="margin-bottom">8pt</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="origin-style">
		
	</xsl:attribute-set>

	<xsl:attribute-set name="term-style">
		<xsl:attribute name="margin-bottom">10pt</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="figure-name-style">
		<xsl:attribute name="font-weight">bold</xsl:attribute>
		<xsl:attribute name="text-align">center</xsl:attribute>
		<xsl:attribute name="margin-top">12pt</xsl:attribute>
		<xsl:attribute name="margin-bottom">12pt</xsl:attribute>
		<xsl:attribute name="keep-with-previous">always</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="formula-style">
		
	</xsl:attribute-set>

	<xsl:attribute-set name="image-style">
		<xsl:attribute name="text-align">center</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="figure-pseudocode-p-style">
		
	</xsl:attribute-set>

	<xsl:attribute-set name="image-graphic-style">
		<xsl:attribute name="width">100%</xsl:attribute>
		<xsl:attribute name="content-height">scale-to-fit</xsl:attribute>
		<xsl:attribute name="scaling">uniform</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="tt-style">
		<xsl:attribute name="font-family">Courier</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="sourcecode-name-style">
		<xsl:attribute name="font-size">11pt</xsl:attribute>
		<xsl:attribute name="font-weight">bold</xsl:attribute>
		<xsl:attribute name="text-align">center</xsl:attribute>
		<xsl:attribute name="margin-bottom">12pt</xsl:attribute>
		<xsl:attribute name="keep-with-previous">always</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="domain-style">
				
	</xsl:attribute-set>

	<xsl:attribute-set name="admitted-style">

	</xsl:attribute-set>

	<xsl:attribute-set name="deprecates-style">
		
		
	</xsl:attribute-set>

	<xsl:attribute-set name="definition-style">
		<xsl:attribute name="margin-bottom">6pt</xsl:attribute>
	</xsl:attribute-set>

	<xsl:variable name="color-added-text">
		<xsl:text>rgb(0, 255, 0)</xsl:text>
	</xsl:variable>
	<xsl:attribute-set name="add-style">
		<xsl:attribute name="color">red</xsl:attribute>
		<xsl:attribute name="text-decoration">underline</xsl:attribute>
	</xsl:attribute-set>

	<xsl:variable name="color-deleted-text">
		<xsl:text>red</xsl:text>
	</xsl:variable>
	<xsl:attribute-set name="del-style">
		<xsl:attribute name="color">
			<xsl:value-of select="$color-deleted-text"/>
		</xsl:attribute>
		<xsl:attribute name="text-decoration">line-through</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="mathml-style">
		<xsl:attribute name="font-family">STIX Two Math</xsl:attribute>
		<xsl:attribute name="font-family">Cambria Math</xsl:attribute>
	</xsl:attribute-set>

	<xsl:attribute-set name="list-style">
		
	</xsl:attribute-set>

	<xsl:variable name="border-block-added">2.5pt solid rgb(0, 176, 80)</xsl:variable>
	<xsl:variable name="border-block-deleted">2.5pt solid rgb(255, 0, 0)</xsl:variable>
	
	<!-- ================= -->
	<!-- END Attribute sets -->
	<!-- ================= -->
	
	
	<!-- =============================== -->
	<!-- Sections ordering -->
	<!-- =============================== -->
	

	<xsl:template name="processPrefaceSectionsDefault">
		<xsl:apply-templates select="/*/ns:preface/ns:abstract"/>
		<xsl:apply-templates select="/*/ns:preface/ns:foreword"/>
		<xsl:apply-templates select="/*/ns:preface/ns:introduction"/>
		<xsl:apply-templates select="/*/ns:preface/*[local-name() != 'abstract' and local-name() != 'foreword' and local-name() != 'introduction' and local-name() != 'acknowledgements']"/>
		<xsl:apply-templates select="/*/ns:preface/ns:acknowledgements"/>
	</xsl:template>

	<xsl:template name="processMainSectionsDefault">
		<xsl:apply-templates select="/*/ns:sections/ns:clause[@type='scope']"/>
		<!-- Normative references  -->
		<xsl:apply-templates select="/*/ns:bibliography/ns:references[@normative='true']"/>
		<!-- Terms and definitions -->
		<xsl:apply-templates select="/*/ns:sections/ns:terms |                        /*/ns:sections/ns:clause[.//ns:terms] |                       /*/ns:sections/ns:definitions |                        /*/ns:sections/ns:clause[.//ns:definitions]"/>
		<!-- Another main sections -->
		<xsl:apply-templates select="/*/ns:sections/*[local-name() != 'terms' and
		local-name() != 'definitions' and
		not(@type='scope') and
		not(local-name() = 'clause' and .//ns:terms) and
		not(local-name() = 'clause' and .//ns:definitions)]"/>
		<xsl:apply-templates select="/*/ns:annex"/>
		<!-- Bibliography -->
		<xsl:apply-templates select="/*/ns:bibliography/ns:references[not(@normative='true')]"/>
	</xsl:template>
	<!-- =============================== -->
	<!-- END Sections ordering -->
	<!-- =============================== -->

	<xsl:template match="text()">
		<xsl:value-of select="."/>
	</xsl:template>

	<xsl:template match="ns:br">
		<xsl:value-of select="$linebreak"/>
	</xsl:template>


	<!-- =========================== -->
	<!-- Table processing -->
	<!-- =========================== -->
	<xsl:template match="ns:td//text() | ns:th//text() | ns:dt//text() | ns:dd//text()" priority="1">
		<!-- <xsl:call-template name="add-zero-spaces"/> -->
		<xsl:call-template name="add-zero-spaces-java"/>
	</xsl:template>

	<xsl:template match="ns:table" name="table">
		<xsl:variable name="table-preamble">
			
			
		</xsl:variable>
		<xsl:variable name="table">
			<xsl:variable name="simple-table">
				<xsl:call-template name="getSimpleTable"/>
			</xsl:variable>
			
			<xsl:variable name="cols-count" select="count(xalan:nodeset($simple-table)/*/tr[1]/td)"/>
			
			<xsl:variable name="colwidths">
				<xsl:if test="not(ns:colgroup/ns:col)">
					<xsl:call-template name="calculate-column-widths">
						<xsl:with-param name="cols-count" select="$cols-count"/>
						<xsl:with-param name="table" select="$simple-table"/>
					</xsl:call-template>
				</xsl:if>
			</xsl:variable>
			
			<xsl:variable name="margin-left">
				<xsl:choose>
					<xsl:when test="sum(xalan:nodeset($colwidths)//column) &gt; 75">15</xsl:when>
					<xsl:otherwise>0</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<fo:block-container margin-left="-{$margin-left}mm" margin-right="-{$margin-left}mm">
				<xsl:attribute name="font-size">10pt</xsl:attribute>
				<xsl:attribute name="margin-top">12pt</xsl:attribute>
				<xsl:attribute name="margin-left">0mm</xsl:attribute>
				<xsl:attribute name="margin-right">0mm</xsl:attribute>
				<xsl:attribute name="margin-bottom">8pt</xsl:attribute>
				<xsl:variable name="table_width">
					<!-- for centered table always 100% (@width will be set for middle/second cell of outer table) -->
					100%
				</xsl:variable>
				<xsl:variable name="table_attributes">
					<attribute name="table-layout">fixed</attribute>
					<attribute name="width">
						<xsl:value-of select="normalize-space($table_width)"/>
					</attribute>
					<attribute name="margin-left">
						<xsl:value-of select="$margin-left"/>mm</attribute>
					<attribute name="margin-right">
						<xsl:value-of select="$margin-left"/>mm</attribute>
					<attribute name="border">1.5pt solid black</attribute>
					<xsl:if test="ns:thead">
						<attribute name="border-top">1pt solid black</attribute>
					</xsl:if>
					<xsl:if test="ancestor::ns:table">
						<!-- for internal table in table cell -->
						<attribute name="border">0.5pt solid black</attribute>
					</xsl:if>
					<attribute name="margin-left">0mm</attribute>
					<attribute name="margin-right">0mm</attribute>
				</xsl:variable>
				<fo:table id="{@id}" table-omit-footer-at-break="true">
					<xsl:for-each select="xalan:nodeset($table_attributes)/attribute">
						<xsl:attribute name="{@name}">
							<xsl:value-of select="."/>
						</xsl:attribute>
					</xsl:for-each>
					<xsl:variable name="isNoteOrFnExist" select="./ns:note or .//ns:fn[local-name(..) != 'name']"/>
					<xsl:if test="$isNoteOrFnExist = 'true'">
						<xsl:attribute name="border-bottom">0pt solid black</xsl:attribute>
						<!-- set 0pt border, because there is a separete table below for footer  -->
					</xsl:if>
					<xsl:choose>
						<xsl:when test="ns:colgroup/ns:col">
							<xsl:for-each select="ns:colgroup/ns:col">
								<fo:table-column column-width="{@width}"/>
							</xsl:for-each>
						</xsl:when>
						<xsl:otherwise>
							<xsl:for-each select="xalan:nodeset($colwidths)//column">
								<xsl:choose>
									<xsl:when test=". = 1 or . = 0">
										<fo:table-column column-width="proportional-column-width(2)"/>
									</xsl:when>
									<xsl:otherwise>
										<fo:table-column column-width="proportional-column-width({.})"/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:for-each>
						</xsl:otherwise>
					</xsl:choose>
					<xsl:choose>
						<xsl:when test="not(ns:tbody) and ns:thead">
							<xsl:apply-templates select="ns:thead" mode="process_tbody"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:apply-templates/>
						</xsl:otherwise>
					</xsl:choose>
				</fo:table>
				<xsl:variable name="colgroup" select="ns:colgroup"/>
				<xsl:for-each select="ns:tbody">
					<!-- select context to tbody -->
					<xsl:call-template name="insertTableFooterInSeparateTable">
						<xsl:with-param name="table_attributes" select="$table_attributes"/>
						<xsl:with-param name="colwidths" select="$colwidths"/>
						<xsl:with-param name="colgroup" select="$colgroup"/>
					</xsl:call-template>
				</xsl:for-each>
			</fo:block-container>
		</xsl:variable>
		<xsl:variable name="isAdded" select="@added"/>
		<xsl:variable name="isDeleted" select="@deleted"/>
		<xsl:choose>
			<xsl:when test="@width">
				<!-- centered table when table name is centered (see table-name-style) -->
				<fo:table table-layout="fixed" width="100%">
					<fo:table-column column-width="proportional-column-width(1)"/>
					<fo:table-column column-width="{@width}"/>
					<fo:table-column column-width="proportional-column-width(1)"/>
					<fo:table-body>
						<fo:table-row>
							<fo:table-cell column-number="2">
								<xsl:copy-of select="$table-preamble"/>
								<fo:block>
									<xsl:call-template name="setTrackChangesStyles">
										<xsl:with-param name="isAdded" select="$isAdded"/>
										<xsl:with-param name="isDeleted" select="$isDeleted"/>
									</xsl:call-template>
									<xsl:copy-of select="$table"/>
								</fo:block>
							</fo:table-cell>
						</fo:table-row>
					</fo:table-body>
				</fo:table>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="$isAdded = 'true' or $isDeleted = 'true'">
						<xsl:copy-of select="$table-preamble"/>
						<fo:block>
							<xsl:call-template name="setTrackChangesStyles">
								<xsl:with-param name="isAdded" select="$isAdded"/>
								<xsl:with-param name="isDeleted" select="$isDeleted"/>
							</xsl:call-template>
							<xsl:copy-of select="$table"/>
						</fo:block>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="$table-preamble"/>
						<xsl:copy-of select="$table"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="ns:table/ns:name"/>
	<xsl:template match="ns:table/ns:name" mode="presentation">
		<xsl:param name="continued"/>
		<xsl:if test="normalize-space() != ''">
			<fo:block xsl:use-attribute-sets="table-name-style">
				<xsl:attribute name="margin-bottom">0pt</xsl:attribute>
				<xsl:choose>
					<xsl:when test="$continued = 'true'">
						<xsl:apply-templates/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates/>
					</xsl:otherwise>
				</xsl:choose>
			</fo:block>
		</xsl:if>
	</xsl:template>

	<xsl:template name="calculate-columns-numbers">
		<xsl:param name="table-row"/>
		<xsl:variable name="columns-count" select="count($table-row/*)"/>
		<xsl:variable name="sum-colspans" select="sum($table-row/*/@colspan)"/>
		<xsl:variable name="columns-with-colspan" select="count($table-row/*[@colspan])"/>
		<xsl:value-of select="$columns-count + $sum-colspans - $columns-with-colspan"/>
	</xsl:template>

	<xsl:template name="calculate-column-widths">
		<xsl:param name="table"/>
		<xsl:param name="cols-count"/>
		<xsl:param name="curr-col" select="1"/>
		<xsl:param name="width" select="0"/>
		<xsl:if test="$curr-col &lt;= $cols-count">
			<xsl:variable name="widths">
				<xsl:choose>
					<xsl:when test="not($table)">
						<!-- this branch is not using in production, for debug only -->
						<xsl:for-each select="ns:thead//ns:tr">
							<xsl:variable name="words">
								<xsl:call-template name="tokenize">
									<xsl:with-param name="text" select="translate(ns:th[$curr-col],'- —:', '    ')"/>
								</xsl:call-template>
							</xsl:variable>
							<xsl:variable name="max_length">
								<xsl:call-template name="max_length">
									<xsl:with-param name="words" select="xalan:nodeset($words)"/>
								</xsl:call-template>
							</xsl:variable>
							<width>
								<xsl:value-of select="$max_length"/>
							</width>
						</xsl:for-each>
						<xsl:for-each select="ns:tbody//ns:tr">
							<xsl:variable name="words">
								<xsl:call-template name="tokenize">
									<xsl:with-param name="text" select="translate(ns:td[$curr-col],'- —:', '    ')"/>
								</xsl:call-template>
							</xsl:variable>
							<xsl:variable name="max_length">
								<xsl:call-template name="max_length">
									<xsl:with-param name="words" select="xalan:nodeset($words)"/>
								</xsl:call-template>
							</xsl:variable>
							<width>
								<xsl:value-of select="$max_length"/>
							</width>
						</xsl:for-each>
					</xsl:when>
					<xsl:otherwise>
						<xsl:for-each select="xalan:nodeset($table)/*/tr">
							<xsl:variable name="td_text">
								<xsl:apply-templates select="td[$curr-col]" mode="td_text"/>
								
							</xsl:variable>
							<xsl:variable name="words">
								<xsl:variable name="string_with_added_zerospaces">
									<xsl:call-template name="add-zero-spaces-java">
										<xsl:with-param name="text" select="$td_text"/>
									</xsl:call-template>
								</xsl:variable>
								<xsl:call-template name="tokenize">
									<xsl:with-param name="text" select="normalize-space(translate($string_with_added_zerospaces, '​', ' '))"/>
								</xsl:call-template>
							</xsl:variable>
							<xsl:variable name="max_length">
								<xsl:call-template name="max_length">
									<xsl:with-param name="words" select="xalan:nodeset($words)"/>
								</xsl:call-template>
							</xsl:variable>
							<width>
								<xsl:variable name="divider">
									<xsl:choose>
										<xsl:when test="td[$curr-col]/@divide">
											<xsl:value-of select="td[$curr-col]/@divide"/>
										</xsl:when>
										<xsl:otherwise>1</xsl:otherwise>
									</xsl:choose>
								</xsl:variable>
								<xsl:value-of select="$max_length div $divider"/>
							</width>
						</xsl:for-each>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<column>
				<xsl:for-each select="xalan:nodeset($widths)//width">
					<xsl:sort select="." data-type="number" order="descending"/>
					<xsl:if test="position()=1">
						<xsl:value-of select="."/>
					</xsl:if>
				</xsl:for-each>
			</column>
			<xsl:call-template name="calculate-column-widths">
				<xsl:with-param name="cols-count" select="$cols-count"/>
				<xsl:with-param name="curr-col" select="$curr-col +1"/>
				<xsl:with-param name="table" select="$table"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

	<xsl:template match="text()" mode="td_text">
		<xsl:variable name="zero-space">​</xsl:variable>
		<xsl:value-of select="translate(., $zero-space, ' ')"/>
		<xsl:text> </xsl:text>
	</xsl:template>

	
	<xsl:template match="ns:termsource" mode="td_text">
		<xsl:value-of select="ns:origin/@citeas"/>
	</xsl:template>

	<xsl:template match="ns:link" mode="td_text">
		<xsl:value-of select="@target"/>
	</xsl:template>

	<xsl:template match="ns:math" mode="td_text">
		<xsl:variable name="mathml">
			<xsl:for-each select="*">
				<xsl:if test="local-name() != 'unit' and local-name() != 'prefix' and local-name() != 'dimension' and local-name() != 'quantity'">
					<xsl:copy-of select="."/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="math_text" select="normalize-space(xalan:nodeset($mathml))"/>
		<xsl:value-of select="translate($math_text, ' ', '#')"/>
		<!-- mathml images as one 'word' without spaces -->
	</xsl:template>

	
	<xsl:template match="ns:thead"/>
	<xsl:template match="ns:thead" mode="process">
		<xsl:param name="cols-count"/>
		<fo:table-header>
			<xsl:call-template name="table-header-title">
				<xsl:with-param name="cols-count" select="$cols-count"/>
			</xsl:call-template>
			<xsl:apply-templates/>
		</fo:table-header>
	</xsl:template>

	<xsl:template name="table-header-title">
		<xsl:param name="cols-count"/>
		<!-- row for title -->
		<fo:table-row>
			<fo:table-cell number-columns-spanned="{$cols-count}" border-left="1.5pt solid white" border-right="1.5pt solid white" border-top="1.5pt solid white" border-bottom="1.5pt solid black">
				<xsl:apply-templates select="ancestor::ns:table/ns:name" mode="presentation">
					<xsl:with-param name="continued">true</xsl:with-param>
				</xsl:apply-templates>
				<xsl:for-each select="ancestor::ns:table[1]">
					<xsl:call-template name="fn_name_display"/>
				</xsl:for-each>
				<fo:block text-align="right" font-style="italic">
					<xsl:text> </xsl:text>
					<fo:retrieve-table-marker retrieve-class-name="table_continued"/>
				</fo:block>
			</fo:table-cell>
		</fo:table-row>
	</xsl:template>

	<xsl:template match="ns:thead" mode="process_tbody">
		<fo:table-body>
			<xsl:apply-templates/>
		</fo:table-body>
	</xsl:template>

	<xsl:template match="ns:tfoot"/>
	<xsl:template match="ns:tfoot" mode="process">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template name="insertTableFooter">
		<xsl:param name="cols-count"/>
		<xsl:if test="../ns:tfoot">
			<fo:table-footer>
				<xsl:apply-templates select="../ns:tfoot" mode="process"/>
			</fo:table-footer>
		</xsl:if>
	</xsl:template>


	<xsl:template name="insertTableFooterInSeparateTable">
		<xsl:param name="table_attributes"/>
		<xsl:param name="colwidths"/>
		<xsl:param name="colgroup"/>
		<xsl:variable name="isNoteOrFnExist" select="../ns:note or ..//ns:fn[local-name(..) != 'name']"/>
		<xsl:if test="$isNoteOrFnExist = 'true'">
			<xsl:variable name="cols-count">
				<xsl:choose>
					<xsl:when test="xalan:nodeset($colgroup)//ns:col">
						<xsl:value-of select="count(xalan:nodeset($colgroup)//ns:col)"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="count(xalan:nodeset($colwidths)//column)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<fo:table keep-with-previous="always">
				<xsl:for-each select="xalan:nodeset($table_attributes)/attribute">
					<xsl:choose>
						<xsl:when test="@name = 'border-top'">
							<xsl:attribute name="{@name}">0pt solid black</xsl:attribute>
						</xsl:when>
						<xsl:when test="@name = 'border'">
							<xsl:attribute name="{@name}">
								<xsl:value-of select="."/>
							</xsl:attribute>
							<xsl:attribute name="border-top">0pt solid black</xsl:attribute>
						</xsl:when>
						<xsl:otherwise>
							<xsl:attribute name="{@name}">
								<xsl:value-of select="."/>
							</xsl:attribute>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
				<xsl:choose>
					<xsl:when test="xalan:nodeset($colgroup)//ns:col">
						<xsl:for-each select="xalan:nodeset($colgroup)//ns:col">
							<fo:table-column column-width="{@width}"/>
						</xsl:for-each>
					</xsl:when>
					<xsl:otherwise>
						<xsl:for-each select="xalan:nodeset($colwidths)//column">
							<xsl:choose>
								<xsl:when test=". = 1 or . = 0">
									<fo:table-column column-width="proportional-column-width(2)"/>
								</xsl:when>
								<xsl:otherwise>
									<fo:table-column column-width="proportional-column-width({.})"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:for-each>
					</xsl:otherwise>
				</xsl:choose>
				<fo:table-body>
					<fo:table-row>
						<fo:table-cell border="solid black 1pt" padding-left="1mm" padding-right="1mm" padding-top="1mm" number-columns-spanned="{$cols-count}">
							<xsl:attribute name="border-top">solid black 0pt</xsl:attribute>
							<!-- fn will be processed inside 'note' processing -->
							<!-- except gb  -->
							<xsl:apply-templates select="../ns:note" mode="process"/>
							
							
							<!-- horizontal row separator -->
							<!-- fn processing -->
							<xsl:call-template name="fn_display"/>
						</fo:table-cell>
					</fo:table-row>
				</fo:table-body>
			</fo:table>
		</xsl:if>
	</xsl:template>

	<xsl:template match="ns:tbody">
		<xsl:variable name="cols-count">
			<xsl:choose>
				<xsl:when test="../ns:thead">
					<xsl:call-template name="calculate-columns-numbers">
						<xsl:with-param name="table-row" select="../ns:thead/ns:tr[1]"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="calculate-columns-numbers">
						<xsl:with-param name="table-row" select="./ns:tr[1]"/>
					</xsl:call-template>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<!-- if there isn't 'thead' and there is a table's title -->
		<xsl:if test="not(ancestor::ns:table/ns:thead) and ancestor::ns:table/ns:name">
			<fo:table-header>
				<xsl:call-template name="table-header-title">
					<xsl:with-param name="cols-count" select="$cols-count"/>
				</xsl:call-template>
			</fo:table-header>
		</xsl:if>
		<xsl:apply-templates select="../ns:thead" mode="process">
			<xsl:with-param name="cols-count" select="$cols-count"/>
		</xsl:apply-templates>
		<xsl:call-template name="insertTableFooter">
			<xsl:with-param name="cols-count" select="$cols-count"/>
		</xsl:call-template>
		<fo:table-body>
			<xsl:variable name="title_continued">
				<xsl:call-template name="getTitle">
					<xsl:with-param name="name" select="'title-continued'"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="title_start" select="ancestor::ns:table[1]/ns:name/node()[1][self::text()]"/>
			<xsl:variable name="table_number" select="substring-before($title_start, '—')"/>
			<fo:table-row height="0" keep-with-next.within-page="always">
				<fo:table-cell>
					<fo:marker marker-class-name="table_continued"/>
					<fo:block/>
				</fo:table-cell>
			</fo:table-row>
			<fo:table-row height="0" keep-with-next.within-page="always">
				<fo:table-cell>
					<fo:marker marker-class-name="table_continued">
						<xsl:value-of select="$title_continued"/>
					</fo:marker>
					<fo:block/>
				</fo:table-cell>
			</fo:table-row>
			<xsl:apply-templates/>
		</fo:table-body>
	</xsl:template>

	<xsl:template match="ns:tr">
		<xsl:variable name="parent-name" select="local-name(..)"/>
		
		<fo:table-row min-height="4mm">
			<xsl:if test="$parent-name = 'thead'">
				<xsl:attribute name="font-weight">bold</xsl:attribute>
				<xsl:choose>
					<xsl:when test="position() = 1">
						<xsl:attribute name="border-top">solid black 1.5pt</xsl:attribute>
						<xsl:attribute name="border-bottom">solid black 1pt</xsl:attribute>
					</xsl:when>
					<xsl:when test="position() = last()">
						<xsl:attribute name="border-top">solid black 1pt</xsl:attribute>
						<xsl:attribute name="border-bottom">solid black 1.5pt</xsl:attribute>
					</xsl:when>
					<xsl:otherwise>
						<xsl:attribute name="border-top">solid black 1pt</xsl:attribute>
						<xsl:attribute name="border-bottom">solid black 1pt</xsl:attribute>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:if>
			<xsl:if test="$parent-name = 'tfoot'">
				<xsl:attribute name="font-size">9pt</xsl:attribute>
				<xsl:attribute name="border-left">solid black 1pt</xsl:attribute>
				<xsl:attribute name="border-right">solid black 1pt</xsl:attribute>
			</xsl:if>

			<xsl:apply-templates/>
		</fo:table-row>
	</xsl:template>

	<xsl:template match="ns:th">
		<fo:table-cell text-align="{@align}" font-weight="bold" border="solid black 1pt" padding-left="1mm" display-align="center">
			<xsl:attribute name="text-align">
				<xsl:choose>
					<xsl:when test="@align">
						<xsl:call-template name="setAlignment"/>
					</xsl:when>
					<xsl:otherwise>center</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<xsl:attribute name="padding-top">1mm</xsl:attribute>
			<xsl:if test="$lang = 'ar'">
				<xsl:attribute name="padding-right">1mm</xsl:attribute>
			</xsl:if>
			<xsl:if test="@colspan">
				<xsl:attribute name="number-columns-spanned">
					<xsl:value-of select="@colspan"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="@rowspan">
				<xsl:attribute name="number-rows-spanned">
					<xsl:value-of select="@rowspan"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:call-template name="display-align"/>
			<fo:block>
				<xsl:apply-templates/>
			</fo:block>
		</fo:table-cell>
	</xsl:template>

	<xsl:template name="display-align">
		<xsl:if test="@valign">
			<xsl:attribute name="display-align">
				<xsl:choose>
					<xsl:when test="@valign = 'top'">before</xsl:when>
					<xsl:when test="@valign = 'middle'">center</xsl:when>
					<xsl:when test="@valign = 'bottom'">after</xsl:when>
					<xsl:otherwise>before</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
		</xsl:if>
	</xsl:template>

	<xsl:template match="ns:td">
		<fo:table-cell text-align="{@align}" display-align="center" border="solid black 1pt" padding-left="1mm">
			<xsl:attribute name="text-align">
				<xsl:choose>
					<xsl:when test="@align">
						<xsl:call-template name="setAlignment"/>
					</xsl:when>
					<xsl:otherwise>left</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<xsl:if test="$lang = 'ar'">
				<xsl:attribute name="padding-right">1mm</xsl:attribute>
			</xsl:if>
			<xsl:attribute name="padding-top">0.5mm</xsl:attribute>
			<xsl:if test="ancestor::ns:tfoot">
				<xsl:attribute name="border">solid black 0</xsl:attribute>
			</xsl:if>
			<xsl:if test=".//ns:table">
				<xsl:attribute name="padding-right">1mm</xsl:attribute>
			</xsl:if>
			<xsl:if test="@colspan">
				<xsl:attribute name="number-columns-spanned">
					<xsl:value-of select="@colspan"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="@rowspan">
				<xsl:attribute name="number-rows-spanned">
					<xsl:value-of select="@rowspan"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:call-template name="display-align"/>
			<fo:block>
				<xsl:apply-templates/>
			</fo:block>
		</fo:table-cell>
	</xsl:template>

	<xsl:template match="ns:table/ns:note" priority="2"/>
	<xsl:template match="ns:table/ns:note" mode="process">
		<fo:block font-size="10pt" margin-bottom="12pt">
			<xsl:attribute name="font-size">9pt</xsl:attribute>
			<xsl:attribute name="margin-bottom">6pt</xsl:attribute>
			<fo:inline padding-right="2mm">
				<xsl:apply-templates select="ns:name" mode="presentation"/>
			</fo:inline>
			<xsl:apply-templates mode="process"/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:table/ns:note/ns:name" mode="process"/>
	<xsl:template match="ns:table/ns:note/ns:p" mode="process">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template name="fn_display">
		<xsl:variable name="references">
			<xsl:for-each select="..//ns:fn[local-name(..) != 'name']">
				<fn reference="{@reference}" id="{@reference}_{ancestor::*[@id][1]/@id}">
					<xsl:apply-templates/>
				</fn>
			</xsl:for-each>
		</xsl:variable>
		<xsl:for-each select="xalan:nodeset($references)//fn">
			<xsl:variable name="reference" select="@reference"/>
			<xsl:if test="not(preceding-sibling::*[@reference = $reference])">
				<!-- only unique reference puts in note-->
				<fo:block margin-bottom="12pt">
					<xsl:attribute name="font-size">9pt</xsl:attribute>
					<xsl:attribute name="margin-bottom">6pt</xsl:attribute>
					<fo:inline font-size="80%" padding-right="5mm" id="{@id}">
						<xsl:attribute name="alignment-baseline">hanging</xsl:attribute>
						<xsl:value-of select="@reference"/>
					</fo:inline>
					<fo:inline>
						<xsl:copy-of select="./node()"/>
					</fo:inline>
				</fo:block>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="fn_name_display">
		<xsl:for-each select="ns:name//ns:fn">
			<xsl:variable name="reference" select="@reference"/>
			<fo:block id="{@reference}_{ancestor::*[@id][1]/@id}">
				<xsl:value-of select="@reference"/>
			</fo:block>
			<fo:block margin-bottom="12pt">
				<xsl:apply-templates/>
			</fo:block>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="fn_display_figure">
		<xsl:variable name="key_iso">true</xsl:variable>
		<xsl:variable name="references">
			<xsl:for-each select=".//ns:fn[not(parent::ns:name)]">
				<fn reference="{@reference}" id="{@reference}_{ancestor::*[@id][1]/@id}">
					<xsl:apply-templates/>
				</fn>
			</xsl:for-each>
		</xsl:variable>
		<!-- current hierarchy is 'figure' element -->
		<xsl:variable name="following_dl_colwidths">
			<xsl:if test="ns:dl">
				<!-- if there is a 'dl', then set the same columns width as for 'dl' -->
				<xsl:variable name="html-table">
					<xsl:variable name="doc_ns">
						
					</xsl:variable>
					<xsl:variable name="ns">
						<xsl:choose>
							<xsl:when test="normalize-space($doc_ns)  != ''">
								<xsl:value-of select="normalize-space($doc_ns)"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="substring-before(name(/*), '-')"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					
					<xsl:for-each select="ns:dl[1]">
						<tbody>
							<xsl:apply-templates mode="dl"/>
						</tbody>
					</xsl:for-each>
					<!-- </xsl:element> -->
				</xsl:variable>
				<xsl:call-template name="calculate-column-widths">
					<xsl:with-param name="cols-count" select="2"/>
					<xsl:with-param name="table" select="$html-table"/>
				</xsl:call-template>
			</xsl:if>
		</xsl:variable>
		<xsl:variable name="maxlength_dt">
			<xsl:for-each select="ns:dl[1]">
				<xsl:call-template name="getMaxLength_dt"/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:if test="xalan:nodeset($references)//fn">
			<fo:block>
				<fo:table width="95%" table-layout="fixed">
					<xsl:if test="normalize-space($key_iso) = 'true'">
						<xsl:attribute name="font-size">10pt</xsl:attribute>
					</xsl:if>
					<xsl:choose>
						<!-- if there 'dl', then set same columns width -->
						<xsl:when test="xalan:nodeset($following_dl_colwidths)//column">
							<xsl:call-template name="setColumnWidth_dl">
								<xsl:with-param name="colwidths" select="$following_dl_colwidths"/>
								<xsl:with-param name="maxlength_dt" select="$maxlength_dt"/>
							</xsl:call-template>
						</xsl:when>
						<xsl:otherwise>
							<fo:table-column column-width="15%"/>
							<fo:table-column column-width="85%"/>
						</xsl:otherwise>
					</xsl:choose>
					<fo:table-body>
						<xsl:for-each select="xalan:nodeset($references)//fn">
							<xsl:variable name="reference" select="@reference"/>
							<xsl:if test="not(preceding-sibling::*[@reference = $reference])">
								<!-- only unique reference puts in note-->
								<fo:table-row>
									<fo:table-cell>
										<fo:block>
											<fo:inline font-size="80%" padding-right="5mm" vertical-align="super" id="{@id}">
												<xsl:value-of select="@reference"/>
											</fo:inline>
										</fo:block>
									</fo:table-cell>
									<fo:table-cell>
										<fo:block text-align="justify" margin-bottom="12pt">
											<xsl:if test="normalize-space($key_iso) = 'true'">
												<xsl:attribute name="margin-bottom">0</xsl:attribute>
											</xsl:if>
											<xsl:copy-of select="./node()"/>
										</fo:block>
									</fo:table-cell>
								</fo:table-row>
							</xsl:if>
						</xsl:for-each>
					</fo:table-body>
				</fo:table>
			</fo:block>
		</xsl:if>
	</xsl:template>

	<xsl:template match="ns:fn">

		<fo:inline font-size="80%" keep-with-previous.within-line="always">
			<xsl:if test="ancestor::ns:td">
				<xsl:attribute name="font-weight">normal</xsl:attribute>

				<xsl:attribute name="baseline-shift">15%</xsl:attribute>
			</xsl:if>
			<fo:basic-link internal-destination="{@reference}_{ancestor::*[@id][1]/@id}" fox:alt-text="{@reference}">
				<xsl:value-of select="@reference"/>
			</fo:basic-link>
		</fo:inline>
	</xsl:template>

	<xsl:template match="ns:fn/ns:p">
		<fo:inline>
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>

	<xsl:template match="ns:dl">
		<xsl:variable name="isAdded" select="@added"/>
		<xsl:variable name="isDeleted" select="@deleted"/>
		<fo:block-container>
			<xsl:if test="not(ancestor::ns:quote)">
				<xsl:attribute name="margin-left">0mm</xsl:attribute>
			</xsl:if>
			<xsl:if test="parent::ns:note">
				<xsl:attribute name="margin-left">
					<xsl:choose>
						<xsl:when test="not(ancestor::ns:table)">
							<xsl:value-of select="$note-body-indent"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$note-body-indent-table"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
			</xsl:if>
			<xsl:call-template name="setTrackChangesStyles">
				<xsl:with-param name="isAdded" select="$isAdded"/>
				<xsl:with-param name="isDeleted" select="$isDeleted"/>
			</xsl:call-template>
			<fo:block-container>
				<xsl:attribute name="margin-left">0mm</xsl:attribute>
				<xsl:attribute name="margin-right">0mm</xsl:attribute>
				<xsl:variable name="parent" select="local-name(..)"/>
				<xsl:variable name="key_iso">
					<xsl:if test="$parent = 'figure' or $parent = 'formula'">true</xsl:if>
				</xsl:variable>
				<xsl:choose>
					<xsl:when test="$parent = 'formula' and count(ns:dt) = 1">
						<!-- only one component -->
						<fo:block margin-bottom="12pt" text-align="left">
							<xsl:attribute name="margin-bottom">0</xsl:attribute>
							<xsl:variable name="title-where">
								<xsl:call-template name="getLocalizedString">
									<xsl:with-param name="key">where</xsl:with-param>
								</xsl:call-template>
							</xsl:variable>
							<xsl:value-of select="$title-where"/>
							<xsl:text> </xsl:text>
							<xsl:apply-templates select="ns:dt/*"/>
							<xsl:text/>
							<xsl:apply-templates select="ns:dd/*" mode="inline"/>
						</fo:block>
					</xsl:when>
					<xsl:when test="$parent = 'formula'">
						<!-- a few components -->
						<fo:block margin-bottom="12pt" text-align="left">
							<xsl:attribute name="margin-bottom">6pt</xsl:attribute>
							<xsl:variable name="title-where">
								<xsl:call-template name="getLocalizedString">
									<xsl:with-param name="key">where</xsl:with-param>
								</xsl:call-template>
							</xsl:variable>
							<xsl:value-of select="$title-where"/>
						</fo:block>
					</xsl:when>
					<xsl:when test="$parent = 'figure' and  (not(../@class) or ../@class !='pseudocode')">
						<fo:block font-weight="bold" text-align="left" margin-bottom="12pt" keep-with-next="always">
							<xsl:attribute name="font-size">10pt</xsl:attribute>
							<xsl:attribute name="margin-bottom">0</xsl:attribute>
							<xsl:variable name="title-key">
								<xsl:call-template name="getLocalizedString">
									<xsl:with-param name="key">key</xsl:with-param>
								</xsl:call-template>
							</xsl:variable>
							<xsl:value-of select="$title-key"/>
						</fo:block>
					</xsl:when>
				</xsl:choose>
				<!-- a few components -->
				<xsl:if test="not($parent = 'formula' and count(ns:dt) = 1)">
					<fo:block>
						<xsl:if test="$parent = 'formula'">
							<xsl:attribute name="margin-left">4mm</xsl:attribute>
						</xsl:if>
						<xsl:attribute name="margin-top">12pt</xsl:attribute>
						<fo:block>
							<fo:table width="95%" table-layout="fixed">
								<xsl:choose>
									<xsl:when test="normalize-space($key_iso) = 'true' and $parent = 'formula'">
									</xsl:when>
									<xsl:when test="normalize-space($key_iso) = 'true'">
										<xsl:attribute name="font-size">10pt</xsl:attribute>
									</xsl:when>
								</xsl:choose>
								<!-- create virtual html table for dl/[dt and dd] -->
								<xsl:variable name="html-table">
									<xsl:variable name="doc_ns">
										
									</xsl:variable>
									<xsl:variable name="ns">
										<xsl:choose>
											<xsl:when test="normalize-space($doc_ns)  != ''">
												<xsl:value-of select="normalize-space($doc_ns)"/>
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of select="substring-before(name(/*), '-')"/>
											</xsl:otherwise>
										</xsl:choose>
									</xsl:variable>
									<tbody>
										<xsl:apply-templates mode="dl"/>
									</tbody>
								</xsl:variable>
								
								<xsl:variable name="colwidths">
									<xsl:call-template name="calculate-column-widths">
										<xsl:with-param name="cols-count" select="2"/>
										<xsl:with-param name="table" select="$html-table"/>
									</xsl:call-template>
								</xsl:variable>
								
								<xsl:variable name="maxlength_dt">
									<xsl:call-template name="getMaxLength_dt"/>
								</xsl:variable>
								<xsl:call-template name="setColumnWidth_dl">
									<xsl:with-param name="colwidths" select="$colwidths"/>
									<xsl:with-param name="maxlength_dt" select="$maxlength_dt"/>
								</xsl:call-template>
								<fo:table-body>
									<xsl:apply-templates>
										<xsl:with-param name="key_iso" select="normalize-space($key_iso)"/>
									</xsl:apply-templates>
								</fo:table-body>
							</fo:table>
						</fo:block>
					</fo:block>
				</xsl:if>
			</fo:block-container>
		</fo:block-container>
	</xsl:template>

	<xsl:template name="setColumnWidth_dl">
		<xsl:param name="colwidths"/>
		<xsl:param name="maxlength_dt"/>
		<xsl:choose>
			<xsl:when test="ancestor::ns:dl">
				<!-- second level, i.e. inlined table -->
				<fo:table-column column-width="50%"/>
				<fo:table-column column-width="50%"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<!-- to set width check most wide chars like `W` -->
					<xsl:when test="normalize-space($maxlength_dt) != '' and number($maxlength_dt) &lt;= 2">
						<!-- if dt contains short text like t90, a, etc -->
						<fo:table-column column-width="7%"/>
						<fo:table-column column-width="93%"/>
					</xsl:when>
					<xsl:when test="normalize-space($maxlength_dt) != '' and number($maxlength_dt) &lt;= 5">
						<!-- if dt contains short text like ABC, etc -->
						<fo:table-column column-width="15%"/>
						<fo:table-column column-width="85%"/>
					</xsl:when>
					<xsl:when test="normalize-space($maxlength_dt) != '' and number($maxlength_dt) &lt;= 7">
						<!-- if dt contains short text like ABCDEF, etc -->
						<fo:table-column column-width="20%"/>
						<fo:table-column column-width="80%"/>
					</xsl:when>
					<xsl:when test="normalize-space($maxlength_dt) != '' and number($maxlength_dt) &lt;= 10">
						<!-- if dt contains short text like ABCDEFEF, etc -->
						<fo:table-column column-width="25%"/>
						<fo:table-column column-width="75%"/>
					</xsl:when>
				
					<xsl:when test="xalan:nodeset($colwidths)/column[1] div xalan:nodeset($colwidths)/column[2] &gt; 1.3">
						<fo:table-column column-width="50%"/>
						<fo:table-column column-width="50%"/>
					</xsl:when>
					<xsl:when test="xalan:nodeset($colwidths)/column[1] div xalan:nodeset($colwidths)/column[2] &gt; 0.5">
						<fo:table-column column-width="40%"/>
						<fo:table-column column-width="60%"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:for-each select="xalan:nodeset($colwidths)//column">
							<xsl:choose>
								<xsl:when test=". = 1 or . = 0">
									<fo:table-column column-width="proportional-column-width(2)"/>
								</xsl:when>
								<xsl:otherwise>
									<fo:table-column column-width="proportional-column-width({.})"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:for-each>
					</xsl:otherwise>
				</xsl:choose>
				
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="getMaxLength_dt">
		<xsl:variable name="lengths">
			<xsl:for-each select="ns:dt">
				<xsl:variable name="maintext_length" select="string-length(normalize-space(.))"/>
				<xsl:variable name="attributes">
					<xsl:for-each select=".//@open">
						<xsl:value-of select="."/>
					</xsl:for-each>
					<xsl:for-each select=".//@close">
						<xsl:value-of select="."/>
					</xsl:for-each>
				</xsl:variable>
				<length>
					<xsl:value-of select="string-length(normalize-space(.)) + string-length($attributes)"/>
				</length>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="maxLength">
			
			<xsl:for-each select="xalan:nodeset($lengths)/length">
				<xsl:sort select="." data-type="number" order="descending"/>
				<xsl:if test="position() = 1">
					<xsl:value-of select="."/>
				</xsl:if>
			</xsl:for-each>
		</xsl:variable>
		
		<xsl:value-of select="$maxLength"/>
	</xsl:template>

	<xsl:template match="ns:dl/ns:note" priority="2">
		<xsl:param name="key_iso"/>
		<!-- <tr>
			<td>NOTE</td>
			<td>
				<xsl:apply-templates />
			</td>
		</tr>
		 -->
		<fo:table-row>
			<fo:table-cell>
				<fo:block margin-top="6pt">
					<xsl:if test="normalize-space($key_iso) = 'true'">
						<xsl:attribute name="margin-top">0</xsl:attribute>
					</xsl:if>
					<xsl:apply-templates select="ns:name" mode="presentation"/>
				</fo:block>
			</fo:table-cell>
			<fo:table-cell>
				<fo:block>
					<xsl:apply-templates/>
				</fo:block>
			</fo:table-cell>
		</fo:table-row>
	</xsl:template>

	<xsl:template match="ns:dt" mode="dl">
		<tr>
			<td>
				<xsl:apply-templates/>
			</td>
			<td>
				<xsl:apply-templates select="following-sibling::ns:dd[1]" mode="process"/>
			</td>
		</tr>
	</xsl:template>

	<xsl:template match="ns:dt">
		<xsl:param name="key_iso"/>
		<fo:table-row>
			<fo:table-cell>
				<fo:block margin-top="6pt">
					<xsl:attribute name="margin-top">0pt</xsl:attribute>
					<xsl:if test="normalize-space($key_iso) = 'true'">
						<xsl:attribute name="margin-top">0</xsl:attribute>
					</xsl:if>
					<xsl:apply-templates/>
				</fo:block>
			</fo:table-cell>
			<fo:table-cell>
				<fo:block>
					
					<xsl:apply-templates select="following-sibling::ns:dd[1]" mode="process"/>
				</fo:block>
			</fo:table-cell>
		</fo:table-row>
		
	</xsl:template>

	<xsl:template match="ns:dd" mode="dl"/>
	<xsl:template match="ns:dd" mode="dl_process">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="ns:dd"/>
	<xsl:template match="ns:dd" mode="process">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="ns:dd/ns:p" mode="inline">
		<fo:inline>
			<xsl:text> </xsl:text>
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>
	
	<!-- ====================== -->
	<!-- Table normalization (no colspan, rowspan) -->
	<!-- ====================== -->
	<xsl:template name="getSimpleTable">
		<xsl:variable name="simple-table">
			<!-- Step 1. colspan processing -->
			<xsl:variable name="simple-table-colspan">
				<tbody>
					<xsl:apply-templates mode="simple-table-colspan"/>
				</tbody>
			</xsl:variable>
			<!-- Step 2. rowspan processing -->
			<xsl:variable name="simple-table-rowspan">
				<xsl:apply-templates select="xalan:nodeset($simple-table-colspan)" mode="simple-table-rowspan"/>
			</xsl:variable>
			<xsl:copy-of select="xalan:nodeset($simple-table-rowspan)"/>
			
		</xsl:variable>
		<xsl:copy-of select="$simple-table"/>
	</xsl:template>

	<xsl:template match="ns:thead | ns:tbody" mode="simple-table-colspan">
		<xsl:apply-templates mode="simple-table-colspan"/>
	</xsl:template>

	<xsl:template match="ns:fn" mode="simple-table-colspan"/>
	<xsl:template match="ns:th | ns:td" mode="simple-table-colspan">
		<xsl:choose>
			<xsl:when test="@colspan">
				<xsl:variable name="td">
					<xsl:element name="td">
						<xsl:attribute name="divide">
							<xsl:value-of select="@colspan"/>
						</xsl:attribute>
						<xsl:apply-templates select="@*" mode="simple-table-colspan"/>
						<xsl:apply-templates mode="simple-table-colspan"/>
					</xsl:element>
				</xsl:variable>
				<xsl:call-template name="repeatNode">
					<xsl:with-param name="count" select="@colspan"/>
					<xsl:with-param name="node" select="$td"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:element name="td">
					<xsl:apply-templates select="@*" mode="simple-table-colspan"/>
					<xsl:apply-templates mode="simple-table-colspan"/>
				</xsl:element>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="@colspan" mode="simple-table-colspan"/>
	<xsl:template match="ns:tr" mode="simple-table-colspan">
		<xsl:element name="tr">
			<xsl:apply-templates select="@*" mode="simple-table-colspan"/>
			<xsl:apply-templates mode="simple-table-colspan"/>
		</xsl:element>
	</xsl:template>

	<xsl:template match="@*|node()" mode="simple-table-colspan">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="simple-table-colspan"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template name="repeatNode">
		<xsl:param name="count"/>
		<xsl:param name="node"/>
		<xsl:if test="$count &gt; 0">
			<xsl:call-template name="repeatNode">
				<xsl:with-param name="count" select="$count - 1"/>
				<xsl:with-param name="node" select="$node"/>
			</xsl:call-template>
			<xsl:copy-of select="$node"/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="@*|node()" mode="simple-table-rowspan">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="simple-table-rowspan"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="tbody" mode="simple-table-rowspan">
		<xsl:copy>
			<xsl:copy-of select="tr[1]"/>
			<xsl:apply-templates select="tr[2]" mode="simple-table-rowspan">
				<xsl:with-param name="previousRow" select="tr[1]"/>
			</xsl:apply-templates>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="tr" mode="simple-table-rowspan">
		<xsl:param name="previousRow"/>
		<xsl:variable name="currentRow" select="."/>
		<xsl:variable name="normalizedTDs">
			<xsl:for-each select="xalan:nodeset($previousRow)//td">
				<xsl:choose>
					<xsl:when test="@rowspan &gt; 1">
						<xsl:copy>
							<xsl:attribute name="rowspan">
								<xsl:value-of select="@rowspan - 1"/>
							</xsl:attribute>
							<xsl:copy-of select="@*[not(name() = 'rowspan')]"/>
							<xsl:copy-of select="node()"/>
						</xsl:copy>
					</xsl:when>
					<xsl:otherwise>
						<xsl:copy-of select="$currentRow/td[1 + count(current()/preceding-sibling::td[not(@rowspan) or (@rowspan = 1)])]"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="newRow">
			<xsl:copy>
				<xsl:copy-of select="$currentRow/@*"/>
				<xsl:copy-of select="xalan:nodeset($normalizedTDs)"/>
			</xsl:copy>
		</xsl:variable>
		<xsl:copy-of select="$newRow"/>
		<xsl:apply-templates select="following-sibling::tr[1]" mode="simple-table-rowspan">
			<xsl:with-param name="previousRow" select="$newRow"/>
		</xsl:apply-templates>
	</xsl:template>
	<!-- ====================== -->
	<!-- END Table normalization (no colspan, rowspan) -->
	<!-- ====================== -->
	<!-- =========================== -->
	<!-- END Table processing -->
	<!-- =========================== -->


	<!-- =========================== -->
	<!-- Rich text formatting -->
	<!-- =========================== -->
	<xsl:template match="ns:em">
		<fo:inline font-style="italic">
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>

	<xsl:template match="ns:strong | ns:b">
		<fo:inline font-weight="bold">
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>

	<xsl:template match="ns:padding">
		<fo:inline padding-right="{@value}"> </fo:inline>
	</xsl:template>

	<xsl:template match="ns:sup">
		<fo:inline font-size="80%" vertical-align="super">
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>

	<xsl:template match="ns:sub">
		<fo:inline font-size="80%" vertical-align="sub">
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>

	<xsl:template match="ns:tt">
		<fo:inline xsl:use-attribute-sets="tt-style">
			<xsl:variable name="font-size">10</xsl:variable>
			<xsl:if test="$font-size != ''">
				<xsl:attribute name="font-size">
					<xsl:choose>
						<xsl:when test="ancestor::ns:note">
							<xsl:value-of select="$font-size * 0.91"/>pt</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$font-size"/>pt</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>

	<xsl:template match="ns:underline">
		<fo:inline text-decoration="underline">
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>

	<xsl:template match="ns:add">
		<xsl:choose>
			<xsl:when test="@amendment">
				<fo:inline>
					<xsl:call-template name="insertTag">
						<xsl:with-param name="kind">A</xsl:with-param>
						<xsl:with-param name="value">
							<xsl:value-of select="@amendment"/>
						</xsl:with-param>
					</xsl:call-template>
					<xsl:apply-templates/>
					<xsl:call-template name="insertTag">
						<xsl:with-param name="type">closing</xsl:with-param>
						<xsl:with-param name="kind">A</xsl:with-param>
						<xsl:with-param name="value">
							<xsl:value-of select="@amendment"/>
						</xsl:with-param>
					</xsl:call-template>
				</fo:inline>
			</xsl:when>
			<xsl:when test="@corrigenda">
				<fo:inline>
					<xsl:call-template name="insertTag">
						<xsl:with-param name="kind">C</xsl:with-param>
						<xsl:with-param name="value">
							<xsl:value-of select="@corrigenda"/>
						</xsl:with-param>
					</xsl:call-template>
					<xsl:apply-templates/>
					<xsl:call-template name="insertTag">
						<xsl:with-param name="type">closing</xsl:with-param>
						<xsl:with-param name="kind">C</xsl:with-param>
						<xsl:with-param name="value">
							<xsl:value-of select="@corrigenda"/>
						</xsl:with-param>
					</xsl:call-template>
				</fo:inline>
			</xsl:when>
			<xsl:otherwise>
				<fo:inline xsl:use-attribute-sets="add-style">
					<xsl:apply-templates/>
				</fo:inline>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="insertTag">
		<xsl:param name="type"/>
		<xsl:param name="kind"/>
		<xsl:param name="value"/>
		<xsl:variable name="add_width" select="string-length($value) * 20"/>
		<xsl:variable name="maxwidth" select="60 + $add_width"/>
		<fo:instream-foreign-object fox:alt-text="OpeningTag" baseline-shift="-20%">
			
			<xsl:attribute name="height">5mm</xsl:attribute>
			<xsl:attribute name="content-width">100%</xsl:attribute>
			<xsl:attribute name="content-width">scale-down-to-fit</xsl:attribute>
			<xsl:attribute name="scaling">uniform</xsl:attribute>
			<svg xmlns="http://www.w3.org/2000/svg" width="{$maxwidth + 32}" height="80">
				<g>
					<xsl:if test="$type = 'closing'">
						<xsl:attribute name="transform">scale(-1 1) translate(-<xsl:value-of select="$maxwidth + 32"/>,0)</xsl:attribute>
					</xsl:if>
					<polyline points="0,0 {$maxwidth},0 {$maxwidth + 30},40 {$maxwidth},80 0,80 " stroke="black" stroke-width="5" fill="white"/>
					<line x1="0" y1="0" x2="0" y2="80" stroke="black" stroke-width="20"/>
				</g>
				<text font-family="Arial" x="15" y="57" font-size="40pt">
					<xsl:if test="$type = 'closing'">
						<xsl:attribute name="x">25</xsl:attribute>
					</xsl:if>
					<xsl:value-of select="$kind"/>
					<tspan dy="10" font-size="30pt">
						<xsl:value-of select="$value"/>
					</tspan>
				</text>
			</svg>
		</fo:instream-foreign-object>
	</xsl:template>

	<xsl:template match="ns:del">
		<fo:inline xsl:use-attribute-sets="del-style">
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>

	<xsl:template match="ns:hi">
		<fo:inline background-color="yellow">
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>

	<xsl:template match="text()[ancestor::ns:smallcap]">
		<xsl:variable name="text" select="normalize-space(.)"/>
		<fo:inline font-size="75%">
			<xsl:if test="string-length($text) &gt; 0">
				<xsl:call-template name="recursiveSmallCaps">
					<xsl:with-param name="text" select="$text"/>
				</xsl:call-template>
			</xsl:if>
		</fo:inline>
	</xsl:template>

	<xsl:template name="recursiveSmallCaps">
		<xsl:param name="text"/>
		<xsl:variable name="char" select="substring($text,1,1)"/>
		<xsl:variable name="upperCase" select="java:toUpperCase(java:java.lang.String.new($char))"/>
		<xsl:choose>
			<xsl:when test="$char=$upperCase">
				<fo:inline font-size="{100 div 0.75}%">
					<xsl:value-of select="$upperCase"/>
				</fo:inline>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$upperCase"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="string-length($text) &gt; 1">
			<xsl:call-template name="recursiveSmallCaps">
				<xsl:with-param name="text" select="substring($text,2)"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

	<xsl:template name="tokenize">
		<xsl:param name="text"/>
		<xsl:param name="separator" select="' '"/>
		<xsl:choose>
			<xsl:when test="not(contains($text, $separator))">
				<word>
					<xsl:variable name="str_no_en_chars" select="normalize-space(translate($text, $en_chars, ''))"/>
					<xsl:variable name="len_str_no_en_chars" select="string-length($str_no_en_chars)"/>
					<xsl:variable name="len_str_tmp" select="string-length(normalize-space($text))"/>
					<xsl:variable name="len_str">
						<xsl:choose>
							<xsl:when test="normalize-space(translate($text, $upper, '')) = ''">
								<!-- english word in CAPITAL letters -->
								<xsl:value-of select="$len_str_tmp * 1.5"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$len_str_tmp"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:choose>
						<xsl:when test="$len_str_no_en_chars div $len_str &gt; 0.8">
							<!-- means non-english string -->
							<xsl:value-of select="$len_str - $len_str_no_en_chars"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$len_str"/>
						</xsl:otherwise>
					</xsl:choose>
				</word>
			</xsl:when>
			<xsl:otherwise>
				<word>
					<xsl:value-of select="string-length(normalize-space(substring-before($text, $separator)))"/>
				</word>
				<xsl:call-template name="tokenize">
					<xsl:with-param name="text" select="substring-after($text, $separator)"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="max_length">
		<xsl:param name="words"/>
		<xsl:for-each select="$words//word">
			<xsl:sort select="." data-type="number" order="descending"/>
			<xsl:if test="position()=1">
				<xsl:value-of select="."/>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="add-zero-spaces-java">
		<xsl:param name="text" select="."/>
		<!-- add zero-width space (#x200B) after characters: dash, dot, colon, equal, underscore, em dash, thin space  -->
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new($text),'(-|\.|:|=|_|—| )','$1​')"/>
	</xsl:template>

	<xsl:template name="add-zero-spaces-link-java">
		<xsl:param name="text" select="."/>
		<!-- add zero-width space (#x200B) after characters: dash, dot, colon, equal, underscore, em dash, thin space  -->
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new($text),'(-|\.|:|=|_|—| |,)','$1​')"/>
	</xsl:template>

	<xsl:template name="add-zero-spaces">
		<xsl:param name="text" select="."/>
		<xsl:variable name="zero-space-after-chars">-</xsl:variable>
		<xsl:variable name="zero-space-after-dot">.</xsl:variable>
		<xsl:variable name="zero-space-after-colon">:</xsl:variable>
		<xsl:variable name="zero-space-after-equal">=</xsl:variable>
		<xsl:variable name="zero-space-after-underscore">_</xsl:variable>
		<xsl:variable name="zero-space">​</xsl:variable>
		<xsl:choose>
			<xsl:when test="contains($text, $zero-space-after-chars)">
				<xsl:value-of select="substring-before($text, $zero-space-after-chars)"/>
				<xsl:value-of select="$zero-space-after-chars"/>
				<xsl:value-of select="$zero-space"/>
				<xsl:call-template name="add-zero-spaces">
					<xsl:with-param name="text" select="substring-after($text, $zero-space-after-chars)"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="contains($text, $zero-space-after-dot)">
				<xsl:value-of select="substring-before($text, $zero-space-after-dot)"/>
				<xsl:value-of select="$zero-space-after-dot"/>
				<xsl:value-of select="$zero-space"/>
				<xsl:call-template name="add-zero-spaces">
					<xsl:with-param name="text" select="substring-after($text, $zero-space-after-dot)"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="contains($text, $zero-space-after-colon)">
				<xsl:value-of select="substring-before($text, $zero-space-after-colon)"/>
				<xsl:value-of select="$zero-space-after-colon"/>
				<xsl:value-of select="$zero-space"/>
				<xsl:call-template name="add-zero-spaces">
					<xsl:with-param name="text" select="substring-after($text, $zero-space-after-colon)"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="contains($text, $zero-space-after-equal)">
				<xsl:value-of select="substring-before($text, $zero-space-after-equal)"/>
				<xsl:value-of select="$zero-space-after-equal"/>
				<xsl:value-of select="$zero-space"/>
				<xsl:call-template name="add-zero-spaces">
					<xsl:with-param name="text" select="substring-after($text, $zero-space-after-equal)"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="contains($text, $zero-space-after-underscore)">
				<xsl:value-of select="substring-before($text, $zero-space-after-underscore)"/>
				<xsl:value-of select="$zero-space-after-underscore"/>
				<xsl:value-of select="$zero-space"/>
				<xsl:call-template name="add-zero-spaces">
					<xsl:with-param name="text" select="substring-after($text, $zero-space-after-underscore)"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$text"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="add-zero-spaces-equal">
		<xsl:param name="text" select="."/>
		<xsl:variable name="zero-space-after-equals">==========</xsl:variable>
		<xsl:variable name="zero-space-after-equal">=</xsl:variable>
		<xsl:variable name="zero-space">​</xsl:variable>
		<xsl:choose>
			<xsl:when test="contains($text, $zero-space-after-equals)">
				<xsl:value-of select="substring-before($text, $zero-space-after-equals)"/>
				<xsl:value-of select="$zero-space-after-equals"/>
				<xsl:value-of select="$zero-space"/>
				<xsl:call-template name="add-zero-spaces-equal">
					<xsl:with-param name="text" select="substring-after($text, $zero-space-after-equals)"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="contains($text, $zero-space-after-equal)">
				<xsl:value-of select="substring-before($text, $zero-space-after-equal)"/>
				<xsl:value-of select="$zero-space-after-equal"/>
				<xsl:value-of select="$zero-space"/>
				<xsl:call-template name="add-zero-spaces-equal">
					<xsl:with-param name="text" select="substring-after($text, $zero-space-after-equal)"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$text"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="ns:link" name="link">
		<xsl:variable name="target">
			<xsl:choose>
				<xsl:when test="@updatetype = 'true'">
					<xsl:value-of select="concat(normalize-space(@target), '.pdf')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="normalize-space(@target)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="target_text">
			<xsl:choose>
				<xsl:when test="starts-with(normalize-space(@target), 'mailto:')">
					<xsl:value-of select="normalize-space(substring-after(@target, 'mailto:'))"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="normalize-space(@target)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<fo:inline xsl:use-attribute-sets="link-style">
			<xsl:choose>
				<xsl:when test="$target_text = ''">
					<xsl:apply-templates/>
				</xsl:when>
				<xsl:otherwise>
					<fo:basic-link external-destination="{$target}" fox:alt-text="{$target}">
						<xsl:choose>
							<xsl:when test="normalize-space(.) = ''">
								<xsl:call-template name="add-zero-spaces-link-java">
									<xsl:with-param name="text" select="$target_text"/>
								</xsl:call-template>
							</xsl:when>
							<xsl:otherwise>
								<!-- output text from <link>text</link> -->
								<xsl:apply-templates/>
							</xsl:otherwise>
						</xsl:choose>
					</fo:basic-link>
				</xsl:otherwise>
			</xsl:choose>
		</fo:inline>
	</xsl:template>
	<!-- =========================== -->
	<!-- Rich text formatting -->
	<!-- =========================== -->
	
	<!-- =========================== -->
	<!-- Mathml processing -->
	<!-- =========================== -->
	<xsl:template match="mathml:math">
		<xsl:variable name="isAdded" select="@added"/>
		<xsl:variable name="isDeleted" select="@deleted"/>
		<fo:inline xsl:use-attribute-sets="mathml-style">
			<xsl:call-template name="setTrackChangesStyles">
				<xsl:with-param name="isAdded" select="$isAdded"/>
				<xsl:with-param name="isDeleted" select="$isDeleted"/>
			</xsl:call-template>
			<xsl:variable name="mathml">
				<xsl:apply-templates select="." mode="mathml"/>
			</xsl:variable>
			<fo:instream-foreign-object fox:alt-text="Math">
				<xsl:if test="count(ancestor::ns:table) &gt; 1">
					<xsl:attribute name="width">95%</xsl:attribute>
					<xsl:attribute name="content-height">100%</xsl:attribute>
					<xsl:attribute name="content-width">scale-down-to-fit</xsl:attribute>
					<xsl:attribute name="scaling">uniform</xsl:attribute>
				</xsl:if>
			
				<xsl:copy-of select="xalan:nodeset($mathml)"/>
			</fo:instream-foreign-object>
		</fo:inline>
	</xsl:template>

	<xsl:template match="@*|node()" mode="mathml">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="mathml"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="mathml:mtext" mode="mathml">
		<xsl:copy>
			<!-- replace start and end spaces to non-break space -->
			<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),'(^ )|( $)',' ')"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="mathml:mi[. = ',' and not(following-sibling::*[1][local-name() = 'mtext' and text() = ' '])]" mode="mathml">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="mathml"/>
		</xsl:copy>
		<xsl:choose>
			<!-- if in msub, then don't add space -->
			<xsl:when test="ancestor::mathml:mrow[parent::mathml:msub and preceding-sibling::*[1][self::mathml:mrow]]"/>
			<!-- if next char in digit,  don't add space -->
			<xsl:when test="translate(substring(following-sibling::*[1]/text(),1,1),'0123456789','') = ''"/>
			<xsl:otherwise>
				<mathml:mspace width="0.5ex"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="mathml:math/*[local-name()='unit']" mode="mathml"/>
	<xsl:template match="mathml:math/*[local-name()='prefix']" mode="mathml"/>
	<xsl:template match="mathml:math/*[local-name()='dimension']" mode="mathml"/>
	<xsl:template match="mathml:math/*[local-name()='quantity']" mode="mathml"/>
	
	<xsl:template match="ns:formula" name="formula">
		<fo:block-container margin-left="0mm">
			<xsl:if test="parent::ns:note">
				<xsl:attribute name="margin-left">
					<xsl:choose>
						<xsl:when test="not(ancestor::ns:table)">
							<xsl:value-of select="$note-body-indent"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$note-body-indent-table"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
			</xsl:if>
			<fo:block-container margin-left="0mm">
				<fo:block id="{@id}" xsl:use-attribute-sets="formula-style">
					<xsl:apply-templates/>
				</fo:block>
			</fo:block-container>
		</fo:block-container>
	</xsl:template>

	<xsl:template match="ns:formula/ns:stem">
		<fo:block margin-top="6pt" margin-bottom="12pt">
			<fo:table table-layout="fixed" width="100%">
				<fo:table-column column-width="95%"/>
				<fo:table-column column-width="5%"/>
				<fo:table-body>
					<fo:table-row>
						<fo:table-cell display-align="center">
							<fo:block text-align="left" margin-left="5mm">
								<xsl:apply-templates/>
							</fo:block>
						</fo:table-cell>
						<fo:table-cell display-align="center">
							<fo:block text-align="right">
								<xsl:apply-templates select="../ns:name" mode="presentation"/>
							</fo:block>
						</fo:table-cell>
					</fo:table-row>
				</fo:table-body>
			</fo:table>
		</fo:block>
	</xsl:template>


	<xsl:template match="ns:formula/ns:dt/ns:stem">
		<fo:inline>
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>

	<xsl:template match="ns:admitted/ns:stem">
		<fo:inline>
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>

	<xsl:template match="ns:formula/ns:name"/>
	<xsl:template match="ns:formula/ns:name" mode="presentation">
		<xsl:if test="normalize-space() != ''">
			<xsl:text>(</xsl:text>
			<xsl:apply-templates/>
			<xsl:text>)</xsl:text>
		</xsl:if>
	</xsl:template>
	<!-- =========================== -->
	<!-- End Mathml processing -->
	<!-- =========================== -->
	
	<xsl:template match="ns:localityStack"/>
	
	
	<xsl:template match="ns:appendix">
		<fo:block id="{@id}" xsl:use-attribute-sets="appendix-style">
			<xsl:apply-templates select="ns:title" mode="process"/>
		</fo:block>
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="ns:appendix/ns:title"/>
	<xsl:template match="ns:appendix/ns:title" mode="process">
		<fo:inline>
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>

	<xsl:template match="ns:appendix//ns:example" priority="2">
		<fo:block id="{@id}" xsl:use-attribute-sets="appendix-example-style">
			<xsl:apply-templates select="ns:name" mode="presentation"/>
		</fo:block>
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="ns:callout">
		<fo:basic-link internal-destination="{@target}" fox:alt-text="{@target}">&lt;<xsl:apply-templates/>&gt;</fo:basic-link>
	</xsl:template>

	<xsl:template match="ns:annotation">
		<xsl:variable name="annotation-id" select="@id"/>
		<xsl:variable name="callout" select="//*[@target = $annotation-id]/text()"/>
		<fo:block id="{$annotation-id}" white-space="nowrap">
			<fo:inline>
				<xsl:apply-templates>
					<xsl:with-param name="callout" select="concat('&lt;', $callout, '&gt; ')"/>
				</xsl:apply-templates>
			</fo:inline>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:annotation/ns:p">
		<xsl:param name="callout"/>
		<fo:inline id="{@id}">
			<!-- for first p in annotation, put <x> -->
			<xsl:if test="not(preceding-sibling::ns:p)">
				<xsl:value-of select="$callout"/>
			</xsl:if>
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>

	<xsl:template match="ns:modification">
		<xsl:variable name="title-modified">
			<xsl:call-template name="getLocalizedString">
				<xsl:with-param name="key">modified</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$lang = 'zh'">
				<xsl:text>、</xsl:text>
				<xsl:value-of select="$title-modified"/>
				<xsl:text>—</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>, </xsl:text>
				<xsl:value-of select="$title-modified"/>
				<xsl:text> — </xsl:text>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:apply-templates/>
	</xsl:template>

	
	

	<!-- =================== -->
	<!-- Note, term note processing -->
	<!-- =================== -->
	<xsl:template match="ns:note" name="note">
		<fo:block-container id="{@id}" xsl:use-attribute-sets="note-style">
			<fo:block-container margin-left="0mm">
				<fo:block>
					<fo:inline xsl:use-attribute-sets="note-name-style">
						<xsl:apply-templates select="ns:name" mode="presentation"/>
					</fo:inline>
					<xsl:apply-templates/>
				</fo:block>
			</fo:block-container>
		</fo:block-container>
	</xsl:template>

	<xsl:template match="ns:note/ns:p">
		<xsl:variable name="num">
			<xsl:number/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$num = 1">
				<fo:inline xsl:use-attribute-sets="note-p-style">
					<xsl:apply-templates/>
				</fo:inline>
			</xsl:when>
			<xsl:otherwise>
				<fo:block xsl:use-attribute-sets="note-p-style">
					<xsl:apply-templates/>
				</fo:block>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="ns:termnote">
		<fo:block id="{@id}" xsl:use-attribute-sets="termnote-style">
			<fo:inline xsl:use-attribute-sets="termnote-name-style">
				<xsl:apply-templates select="ns:name" mode="presentation"/>
			</fo:inline>
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:note/ns:name | ns:termnote/ns:name"/>
	<xsl:template match="ns:note/ns:name" mode="presentation">
		<xsl:param name="sfx"/>
		<xsl:variable name="suffix">
			<xsl:choose>
				<xsl:when test="$sfx != ''">
					<xsl:value-of select="$sfx"/>
				</xsl:when>
				<xsl:otherwise>
					
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="normalize-space() != ''">
			<xsl:apply-templates/>
			<xsl:value-of select="$suffix"/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="ns:termnote/ns:name" mode="presentation">
		<xsl:param name="sfx"/>
		<xsl:variable name="suffix">
			<xsl:choose>
				<xsl:when test="$sfx != ''">
					<xsl:value-of select="$sfx"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>:</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:if test="normalize-space() != ''">
			<xsl:apply-templates/>
			<xsl:value-of select="$suffix"/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="ns:termnote/ns:p">
		<fo:inline>
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>
	<!-- =================== -->
	<!-- END Note, term note processing -->
	<!-- =================== -->
	
	<!-- =================== -->
	<!-- Terms processing -->
	<!-- =================== -->
	<xsl:template match="ns:terms">
		<fo:block id="{@id}">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:term">
		<fo:block id="{@id}" xsl:use-attribute-sets="term-style">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:term/ns:name"/>
	<xsl:template match="ns:term/ns:name" mode="presentation">
		<xsl:if test="normalize-space() != ''">
			<fo:inline>
				<xsl:apply-templates/>
				
			</fo:inline>
		</xsl:if>
	</xsl:template>

	<xsl:template match="ns:preferred">
		<fo:block line-height="1.1">
			<fo:block font-weight="bold" keep-with-next="always">
				<xsl:apply-templates select="ancestor::ns:term/ns:name" mode="presentation"/>
			</fo:block>
			<fo:block font-weight="bold" keep-with-next="always">
				<xsl:apply-templates/>
			</fo:block>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:domain">
		<fo:inline xsl:use-attribute-sets="domain-style">&lt;<xsl:apply-templates/>&gt;</fo:inline>
		<xsl:text> </xsl:text>
	</xsl:template>

	<xsl:template match="ns:admitted">
		<fo:block xsl:use-attribute-sets="admitted-style">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:deprecates">
		<xsl:variable name="title-deprecated">
			<xsl:call-template name="getLocalizedString">
				<xsl:with-param name="key">deprecated</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>
		<fo:block xsl:use-attribute-sets="deprecates-style">
			<xsl:value-of select="$title-deprecated"/>: <xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:definition">
		<fo:block xsl:use-attribute-sets="definition-style">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:definition[preceding-sibling::ns:domain]">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="ns:definition[preceding-sibling::ns:domain]/ns:p">
		<fo:inline>
			<xsl:apply-templates/>
		</fo:inline>
		<fo:block> </fo:block>
	</xsl:template>

	<xsl:template match="ns:definitions">
		<fo:block id="{@id}">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>


	<!-- =================== -->
	<!-- END Terms processing -->
	<!-- =================== -->

	<!-- ============================= -->
	<!-- Figures, images processing -->
	<!-- ============================= -->
	<xsl:template match="ns:figure" name="figure">
		<xsl:variable name="isAdded" select="@added"/>
		<xsl:variable name="isDeleted" select="@deleted"/>
		<fo:block-container id="{@id}">
			<xsl:call-template name="setTrackChangesStyles">
				<xsl:with-param name="isAdded" select="$isAdded"/>
				<xsl:with-param name="isDeleted" select="$isDeleted"/>
			</xsl:call-template>
			<fo:block>
				<xsl:apply-templates/>
			</fo:block>
			<xsl:call-template name="fn_display_figure"/>
			<xsl:for-each select="ns:note">
				<xsl:call-template name="note"/>
			</xsl:for-each>
			<xsl:apply-templates select="ns:name" mode="presentation"/>
		</fo:block-container>
	</xsl:template>

	<xsl:template match="ns:figure[@class = 'pseudocode']">
		<fo:block id="{@id}">
			<xsl:apply-templates/>
		</fo:block>
		<xsl:apply-templates select="ns:name" mode="presentation"/>
	</xsl:template>

	<xsl:template match="ns:figure[@class = 'pseudocode']//ns:p">
		<fo:block xsl:use-attribute-sets="figure-pseudocode-p-style">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:image">
		<xsl:variable name="isAdded" select="../@added"/>
		<xsl:variable name="isDeleted" select="../@deleted"/>
		<xsl:choose>
			<xsl:when test="ancestor::ns:title">
				<fo:inline padding-left="1mm" padding-right="1mm">
					<xsl:variable name="src">
						<xsl:call-template name="image_src"/>
					</xsl:variable>
					<fo:external-graphic src="{$src}" fox:alt-text="Image {@alt}" vertical-align="middle"/>
				</fo:inline>
			</xsl:when>
			<xsl:otherwise>
				<fo:block xsl:use-attribute-sets="image-style">
					<xsl:variable name="src">
						<xsl:call-template name="image_src"/>
					</xsl:variable>
					<xsl:choose>
						<xsl:when test="$isDeleted = 'true'">
							<!-- enclose in svg -->
							<fo:instream-foreign-object fox:alt-text="Image {@alt}">
								<xsl:attribute name="width">100%</xsl:attribute>
								<xsl:attribute name="content-height">100%</xsl:attribute>
								<xsl:attribute name="content-width">scale-down-to-fit</xsl:attribute>
								<xsl:attribute name="scaling">uniform</xsl:attribute>
								<xsl:apply-templates select="." mode="cross_image"/>
							</fo:instream-foreign-object>
						</xsl:when>
						<xsl:otherwise>
							<fo:external-graphic src="{$src}" fox:alt-text="Image {@alt}" xsl:use-attribute-sets="image-graphic-style"/>
						</xsl:otherwise>
					</xsl:choose>
				</fo:block>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="image_src">
		<xsl:choose>
			<xsl:when test="@mimetype = 'image/svg+xml' and $images/images/image[@id = current()/@id]">
				<xsl:value-of select="$images/images/image[@id = current()/@id]/@src"/>
			</xsl:when>
			<xsl:when test="not(starts-with(@src, 'data:'))">
				<xsl:value-of select="concat('url(file:',$basepath, @src, ')')"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="@src"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="ns:image" mode="cross_image">
		<xsl:choose>
			<xsl:when test="@mimetype = 'image/svg+xml' and $images/images/image[@id = current()/@id]">
				<xsl:variable name="src">
					<xsl:value-of select="$images/images/image[@id = current()/@id]/@src"/>
				</xsl:variable>
				<xsl:variable name="width" select="document($src)/@width"/>
				<xsl:variable name="height" select="document($src)/@height"/>
				<svg xmlns="http://www.w3.org/2000/svg" xml:space="preserve" style="enable-background:new 0 0 595.28 841.89;" height="{$height}" width="{$width}" viewBox="0 0 {$width} {$height}" y="0px" x="0px" id="Layer_1" version="1.1">
					<image xlink:href="{$src}" style="overflow:visible;"/>
				</svg>
			</xsl:when>
			<xsl:when test="not(starts-with(@src, 'data:'))">
				<xsl:variable name="src">
					<xsl:value-of select="concat('url(file:',$basepath, @src, ')')"/>
				</xsl:variable>
				<xsl:variable name="file" select="java:java.io.File.new(@src)"/>
				<xsl:variable name="bufferedImage" select="java:javax.imageio.ImageIO.read($file)"/>
				<xsl:variable name="width" select="java:getWidth($bufferedImage)"/>
				<xsl:variable name="height" select="java:getHeight($bufferedImage)"/>
				<svg xmlns="http://www.w3.org/2000/svg" xml:space="preserve" style="enable-background:new 0 0 595.28 841.89;" height="{$height}" width="{$width}" viewBox="0 0 {$width} {$height}" y="0px" x="0px" id="Layer_1" version="1.1">
					<image xlink:href="{$src}" style="overflow:visible;"/>
				</svg>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="base64String" select="substring-after(@src, 'base64,')"/>
				<xsl:variable name="decoder" select="java:java.util.Base64.getDecoder()"/>
				<xsl:variable name="fileContent" select="java:decode($decoder, $base64String)"/>
				<xsl:variable name="bis" select="java:java.io.ByteArrayInputStream.new($fileContent)"/>
				<xsl:variable name="bufferedImage" select="java:javax.imageio.ImageIO.read($bis)"/>
				<xsl:variable name="width" select="java:getWidth($bufferedImage)"/>
				<xsl:variable name="height" select="java:getHeight($bufferedImage)"/>
			
				<svg xmlns="http://www.w3.org/2000/svg" xml:space="preserve" style="enable-background:new 0 0 595.28 841.89;" height="{$height}" width="{$width}" viewBox="0 0 {$width} {$height}" y="0px" x="0px" id="Layer_1" version="1.1">
					<image xlink:href="{@src}" height="{$height}" width="{$width}" style="overflow:visible;"/>
					<xsl:call-template name="svg_cross">
						<xsl:with-param name="width" select="$width"/>
						<xsl:with-param name="height" select="$height"/>
					</xsl:call-template>
				</svg>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="svg_cross">
		<xsl:param name="width"/>
		<xsl:param name="height"/>
		<line xmlns="http://www.w3.org/2000/svg" x1="0" y1="0" x2="{$width}" y2="{$height}" style="stroke: rgb(255, 0, 0); stroke-width:4px; "/>
		<line xmlns="http://www.w3.org/2000/svg" x1="0" y1="{$height}" x2="{$width}" y2="0" style="stroke: rgb(255, 0, 0); stroke-width:4px; "/>
	</xsl:template>

	<xsl:variable name="figure_name_height">14</xsl:variable>
	<xsl:variable name="width_effective" select="$pageWidth - $marginLeftRight1 - $marginLeftRight2"/>
	<xsl:variable name="height_effective" select="$pageHeight - $marginTop - $marginBottom - $figure_name_height"/>
	<xsl:variable name="image_dpi" select="96"/>
	<xsl:variable name="width_effective_px" select="$width_effective div 25.4 * $image_dpi"/>
	<xsl:variable name="height_effective_px" select="$height_effective div 25.4 * $image_dpi"/>
	<xsl:template match="ns:figure[not(ns:image) and *[local-name() = 'svg']]/ns:name/ns:bookmark" priority="2"/>
	<xsl:template match="ns:figure[not(ns:image)]/*[local-name() = 'svg']" priority="2" name="image_svg">
		<xsl:param name="name"/>
		<xsl:variable name="svg_content">
			<xsl:apply-templates select="." mode="svg_update"/>
		</xsl:variable>
		<xsl:variable name="alt-text">
			<xsl:choose>
				<xsl:when test="normalize-space(../ns:name) != ''">
					<xsl:value-of select="../ns:name"/>
				</xsl:when>
				<xsl:when test="normalize-space($name) != ''">
					<xsl:value-of select="$name"/>
				</xsl:when>
				<xsl:otherwise>Figure</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test=".//*[local-name() = 'a'][*[local-name() = 'rect'] or *[local-name() = 'polygon'] or *[local-name() = 'circle'] or *[local-name() = 'ellipse']]">
				<fo:block>
					<xsl:variable name="width" select="@width"/>
					<xsl:variable name="height" select="@height"/>
					<xsl:variable name="scale_x">
						<xsl:choose>
							<xsl:when test="$width &gt; $width_effective_px">
								<xsl:value-of select="$width_effective_px div $width"/>
							</xsl:when>
							<xsl:otherwise>1</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="scale_y">
						<xsl:choose>
							<xsl:when test="$height * $scale_x &gt; $height_effective_px">
								<xsl:value-of select="$height_effective_px div ($height * $scale_x)"/>
							</xsl:when>
							<xsl:otherwise>1</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="scale">
						<xsl:choose>
							<xsl:when test="$scale_y != 1">
								<xsl:value-of select="$scale_x * $scale_y"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$scale_x"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:variable>
					<xsl:variable name="width_scale" select="round($width * $scale)"/>
					<xsl:variable name="height_scale" select="round($height * $scale)"/>
					<fo:table table-layout="fixed" width="100%">
						<fo:table-column column-width="proportional-column-width(1)"/>
						<fo:table-column column-width="{$width_scale}px"/>
						<fo:table-column column-width="proportional-column-width(1)"/>
						<fo:table-body>
							<fo:table-row>
								<fo:table-cell column-number="2">
									<fo:block>
										<fo:block-container width="{$width_scale}px" height="{$height_scale}px">
											<xsl:if test="../ns:name/ns:bookmark">
												<fo:block line-height="0" font-size="0">
													<xsl:for-each select="../ns:name/ns:bookmark">
														<xsl:call-template name="bookmark"/>
													</xsl:for-each>
												</fo:block>
											</xsl:if>
											<fo:block text-depth="0" line-height="0" font-size="0">
												<fo:instream-foreign-object fox:alt-text="{$alt-text}">
													<xsl:attribute name="width">100%</xsl:attribute>
													<xsl:attribute name="content-height">100%</xsl:attribute>
													<xsl:attribute name="content-width">scale-down-to-fit</xsl:attribute>
													<xsl:attribute name="scaling">uniform</xsl:attribute>
													<xsl:apply-templates select="xalan:nodeset($svg_content)" mode="svg_remove_a"/>
												</fo:instream-foreign-object>
											</fo:block>
											<xsl:apply-templates select=".//*[local-name() = 'a'][*[local-name() = 'rect'] or *[local-name() = 'polygon'] or *[local-name() = 'circle'] or *[local-name() = 'ellipse']]" mode="svg_imagemap_links">
												<xsl:with-param name="scale" select="$scale"/>
											</xsl:apply-templates>
										</fo:block-container>
									</fo:block>
								</fo:table-cell>
							</fo:table-row>
						</fo:table-body>
					</fo:table>
				</fo:block>
			</xsl:when>
			<xsl:otherwise>
				<fo:block xsl:use-attribute-sets="image-style">
					<fo:instream-foreign-object fox:alt-text="{$alt-text}">
						<xsl:attribute name="width">100%</xsl:attribute>
						<xsl:attribute name="content-height">100%</xsl:attribute>
						<xsl:attribute name="content-width">scale-down-to-fit</xsl:attribute>
						<!-- effective height 297 - 27.4 - 13 =  256.6 -->
						<!-- effective width 210 - 12.5 - 25 = 172.5 -->
						<!-- effective height / width = 1.48, 1.4 - with title -->
						<xsl:if test="@height &gt; (@width * 1.4)">
							<!-- for images with big height -->
							<xsl:variable name="width" select="((@width * 1.4) div @height) * 100"/>
							<xsl:attribute name="width">
								<xsl:value-of select="$width"/>%</xsl:attribute>
						</xsl:if>
						<xsl:attribute name="scaling">uniform</xsl:attribute>
						<xsl:copy-of select="$svg_content"/>
					</fo:instream-foreign-object>
				</fo:block>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="@*|node()" mode="svg_update">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="svg_update"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="ns:image/@href" mode="svg_update">
		<xsl:attribute name="href" namespace="http://www.w3.org/1999/xlink">
			<xsl:value-of select="."/>
		</xsl:attribute>
	</xsl:template>

	<xsl:template match="ns:figure/ns:image[@mimetype = 'image/svg+xml' and @src[not(starts-with(., 'data:image/'))]]" priority="2">
		<xsl:variable name="svg_content" select="document(@src)"/>
		<xsl:variable name="name" select="ancestor::ns:figure/ns:name"/>
		<xsl:for-each select="xalan:nodeset($svg_content)/node()">
			<xsl:call-template name="image_svg">
				<xsl:with-param name="name" select="$name"/>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="@*|node()" mode="svg_remove_a">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="svg_remove_a"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template match="*[local-name() = 'a']" mode="svg_remove_a">
		<xsl:apply-templates mode="svg_remove_a"/>
	</xsl:template>

	<xsl:template match="*[local-name() = 'a']" mode="svg_imagemap_links">
		<xsl:param name="scale"/>
		<xsl:variable name="dest">
			<xsl:choose>
				<xsl:when test="starts-with(@href, '#')">
					<xsl:value-of select="substring-after(@href, '#')"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="@href"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:for-each select="./*[local-name() = 'rect']">
			<xsl:call-template name="insertSVGMapLink">
				<xsl:with-param name="left" select="floor(@x * $scale)"/>
				<xsl:with-param name="top" select="floor(@y * $scale)"/>
				<xsl:with-param name="width" select="floor(@width * $scale)"/>
				<xsl:with-param name="height" select="floor(@height * $scale)"/>
				<xsl:with-param name="dest" select="$dest"/>
			</xsl:call-template>
		</xsl:for-each>
		<xsl:for-each select="./*[local-name() = 'polygon']">
			<xsl:variable name="points">
				<xsl:call-template name="split">
					<xsl:with-param name="pText" select="@points"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:variable name="x_coords">
				<xsl:for-each select="xalan:nodeset($points)//item[position() mod 2 = 1]">
					<xsl:sort select="." data-type="number"/>
					<x>
						<xsl:value-of select="."/>
					</x>
				</xsl:for-each>
			</xsl:variable>
			<xsl:variable name="y_coords">
				<xsl:for-each select="xalan:nodeset($points)//item[position() mod 2 = 0]">
					<xsl:sort select="." data-type="number"/>
					<y>
						<xsl:value-of select="."/>
					</y>
				</xsl:for-each>
			</xsl:variable>
			<xsl:variable name="x" select="xalan:nodeset($x_coords)//x[1]"/>
			<xsl:variable name="y" select="xalan:nodeset($y_coords)//y[1]"/>
			<xsl:variable name="width" select="xalan:nodeset($x_coords)//x[last()] - $x"/>
			<xsl:variable name="height" select="xalan:nodeset($y_coords)//y[last()] - $y"/>
			<xsl:call-template name="insertSVGMapLink">
				<xsl:with-param name="left" select="floor($x * $scale)"/>
				<xsl:with-param name="top" select="floor($y * $scale)"/>
				<xsl:with-param name="width" select="floor($width * $scale)"/>
				<xsl:with-param name="height" select="floor($height * $scale)"/>
				<xsl:with-param name="dest" select="$dest"/>
			</xsl:call-template>
		</xsl:for-each>
		<xsl:for-each select="./*[local-name() = 'circle']">
			<xsl:call-template name="insertSVGMapLink">
				<xsl:with-param name="left" select="floor((@cx - @r) * $scale)"/>
				<xsl:with-param name="top" select="floor((@cy - @r) * $scale)"/>
				<xsl:with-param name="width" select="floor(@r * 2 * $scale)"/>
				<xsl:with-param name="height" select="floor(@r * 2 * $scale)"/>
				<xsl:with-param name="dest" select="$dest"/>
			</xsl:call-template>
		</xsl:for-each>
		<xsl:for-each select="./*[local-name() = 'ellipse']">
			<xsl:call-template name="insertSVGMapLink">
				<xsl:with-param name="left" select="floor((@cx - @rx) * $scale)"/>
				<xsl:with-param name="top" select="floor((@cy - @ry) * $scale)"/>
				<xsl:with-param name="width" select="floor(@rx * 2 * $scale)"/>
				<xsl:with-param name="height" select="floor(@ry * 2 * $scale)"/>
				<xsl:with-param name="dest" select="$dest"/>
			</xsl:call-template>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="insertSVGMapLink">
		<xsl:param name="left"/>
		<xsl:param name="top"/>
		<xsl:param name="width"/>
		<xsl:param name="height"/>
		<xsl:param name="dest"/>
		<fo:block-container position="absolute" left="{$left}px" top="{$top}px" width="{$width}px" height="{$height}px">
			<fo:block font-size="1pt">
				<fo:basic-link internal-destination="{$dest}" fox:alt-text="svg link">
					<fo:inline-container inline-progression-dimension="100%">
						<fo:block-container height="{$height - 1}px" width="100%">
							<fo:block> </fo:block>
						</fo:block-container>
					</fo:inline-container>
				</fo:basic-link>
			</fo:block>
		</fo:block-container>
	</xsl:template>

	<xsl:template match="ns:figure/ns:name"/>
	

	<xsl:template match="ns:figure/ns:name |
																ns:table/ns:name |
																ns:permission/ns:name |
																ns:recommendation/ns:name |
																ns:requirement/ns:name" mode="bookmarks">
		<xsl:apply-templates mode="bookmarks"/>
		<xsl:text> </xsl:text>
	</xsl:template>

	

	<xsl:template match="*[local-name() = 'figure' or local-name() = 'table' or local-name() = 'permission' or local-name() = 'recommendation' or local-name() = 'requirement']/ns:name/text()" mode="bookmarks" priority="2">
		<xsl:value-of select="."/>
	</xsl:template>

	<xsl:template match="ns:figure/ns:name |
								ns:image/ns:name" mode="presentation">
		<xsl:if test="normalize-space() != ''">
			<fo:block xsl:use-attribute-sets="figure-name-style">
				<xsl:apply-templates/>
			</fo:block>
		</xsl:if>
	</xsl:template>

	<xsl:template match="ns:figure/ns:fn" priority="2"/>
	<xsl:template match="ns:figure/ns:note"/>
	

	<!-- ============================= -->
	<!-- Figures, images processing -->
	<!-- ============================= -->


	<!-- ============================= -->
	<!-- PDF Bookmarks processing -->
	<!-- ============================= -->
	<xsl:template match="node()" mode="bookmarks">
		<xsl:apply-templates mode="bookmarks"/>
	</xsl:template>

	
	<xsl:template match="ns:stem" mode="bookmarks">
		<xsl:apply-templates mode="bookmarks"/>
	</xsl:template>

	<xsl:template name="addBookmarks">
		<xsl:param name="contents"/>
		<xsl:if test="xalan:nodeset($contents)//item">
			<fo:bookmark-tree>
				<xsl:choose>
					<xsl:when test="xalan:nodeset($contents)/doc">
						<xsl:choose>
							<xsl:when test="count(xalan:nodeset($contents)/doc) &gt; 1">
								<xsl:for-each select="xalan:nodeset($contents)/doc">
									<fo:bookmark internal-destination="{contents/item[1]/@id}" starting-state="hide">
										<xsl:if test="@bundle = 'true'">
											<xsl:attribute name="internal-destination">
												<xsl:value-of select="@firstpage_id"/>
											</xsl:attribute>
										</xsl:if>
										<fo:bookmark-title>
											<xsl:choose>
												<xsl:when test="not(normalize-space(@bundle) = 'true')">
													<!-- 'bundle' means several different documents (not language versions) in one xml -->
													<xsl:variable name="bookmark-title_">
														<xsl:call-template name="getLangVersion">
															<xsl:with-param name="lang" select="@lang"/>
															<xsl:with-param name="doctype" select="@doctype"/>
															<xsl:with-param name="title" select="@title-part"/>
														</xsl:call-template>
													</xsl:variable>
													<xsl:choose>
														<xsl:when test="normalize-space($bookmark-title_) != ''">
															<xsl:value-of select="normalize-space($bookmark-title_)"/>
														</xsl:when>
														<xsl:otherwise>
															<xsl:choose>
																<xsl:when test="@lang = 'en'">English</xsl:when>
																<xsl:when test="@lang = 'fr'">Français</xsl:when>
																<xsl:when test="@lang = 'de'">Deutsche</xsl:when>
																<xsl:otherwise>
																	<xsl:value-of select="@lang"/> version</xsl:otherwise>
															</xsl:choose>
														</xsl:otherwise>
													</xsl:choose>
												</xsl:when>
												<xsl:otherwise>
													<xsl:value-of select="@title-part"/>
												</xsl:otherwise>
											</xsl:choose>
										</fo:bookmark-title>
										<xsl:apply-templates select="contents/item" mode="bookmark"/>
										<xsl:call-template name="insertFigureBookmarks">
											<xsl:with-param name="contents" select="contents"/>
										</xsl:call-template>
										<xsl:call-template name="insertTableBookmarks">
											<xsl:with-param name="contents" select="contents"/>
											<xsl:with-param name="lang" select="@lang"/>
										</xsl:call-template>
									</fo:bookmark>
								</xsl:for-each>
							</xsl:when>
							<xsl:otherwise>
								<xsl:for-each select="xalan:nodeset($contents)/doc">
									<xsl:apply-templates select="contents/item" mode="bookmark"/>
									<xsl:call-template name="insertFigureBookmarks">
										<xsl:with-param name="contents" select="contents"/>
									</xsl:call-template>
									<xsl:call-template name="insertTableBookmarks">
										<xsl:with-param name="contents" select="contents"/>
										<xsl:with-param name="lang" select="@lang"/>
									</xsl:call-template>
								</xsl:for-each>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates select="xalan:nodeset($contents)/contents/item" mode="bookmark"/>
					</xsl:otherwise>
				</xsl:choose>
			</fo:bookmark-tree>
		</xsl:if>
	</xsl:template>

	<xsl:template name="insertFigureBookmarks">
		<xsl:param name="contents"/>
		<xsl:if test="xalan:nodeset($contents)/figure">
			<fo:bookmark internal-destination="{xalan:nodeset($contents)/figure[1]/@id}" starting-state="hide">
				<fo:bookmark-title>Figures</fo:bookmark-title>
				<xsl:for-each select="xalan:nodeset($contents)/figure">
					<fo:bookmark internal-destination="{@id}">
						<fo:bookmark-title>
							<xsl:value-of select="normalize-space(title)"/>
						</fo:bookmark-title>
					</fo:bookmark>
				</xsl:for-each>
			</fo:bookmark>
		</xsl:if>
	</xsl:template>

	<xsl:template name="insertTableBookmarks">
		<xsl:param name="contents"/>
		<xsl:param name="lang"/>
		<xsl:if test="xalan:nodeset($contents)/table">
			<fo:bookmark internal-destination="{xalan:nodeset($contents)/table[1]/@id}" starting-state="hide">
				<fo:bookmark-title>
					<xsl:choose>
						<xsl:when test="$lang = 'fr'">Tableaux</xsl:when>
						<xsl:otherwise>Tables</xsl:otherwise>
					</xsl:choose>
				</fo:bookmark-title>
				<xsl:for-each select="xalan:nodeset($contents)/table">
					<fo:bookmark internal-destination="{@id}">
						<fo:bookmark-title>
							<xsl:value-of select="normalize-space(title)"/>
						</fo:bookmark-title>
					</fo:bookmark>
				</xsl:for-each>
			</fo:bookmark>
		</xsl:if>
	</xsl:template>

	<xsl:template name="getLangVersion">
		<xsl:param name="lang"/>
		<xsl:param name="doctype" select="''"/>
		<xsl:param name="title" select="''"/>
		<xsl:choose>
			<xsl:when test="$lang = 'en'">
			
			</xsl:when>
			<xsl:when test="$lang = 'fr'">
				
			</xsl:when>
			<xsl:when test="$lang = 'de'">Deutsche</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$lang"/> version</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="item" mode="bookmark">
		<xsl:choose>
			<xsl:when test="@id != ''">
				<fo:bookmark internal-destination="{@id}" starting-state="hide">
					<fo:bookmark-title>
						<xsl:if test="@section != ''">
							<xsl:value-of select="@section"/>
							<xsl:text> </xsl:text>
						</xsl:if>
						<xsl:value-of select="normalize-space(title)"/>
					</fo:bookmark-title>
					<xsl:apply-templates mode="bookmark"/>
				</fo:bookmark>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates mode="bookmark"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="title" mode="bookmark"/>
	<xsl:template match="text()" mode="bookmark"/>
	
	<xsl:template match="ns:fn" mode="bookmarks"/>
	
	<!-- ============================= -->
	<!-- END PDF Bookmarks processing -->
	<!-- ============================= -->
	
	

	<xsl:template name="getSection">
		<xsl:value-of select="ns:title/ns:tab[1]/preceding-sibling::node()"/>
	</xsl:template>

	<xsl:template name="getName">
		<xsl:choose>
			<xsl:when test="ns:title/ns:tab">
				<xsl:copy-of select="ns:title/ns:tab[1]/following-sibling::node()"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="ns:title/node()"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="insertTitleAsListItem">
		<xsl:param name="provisional-distance-between-starts" select="'9.5mm'"/>
		<xsl:variable name="section">
			<xsl:for-each select="..">
				<xsl:call-template name="getSection"/>
			</xsl:for-each>
		</xsl:variable>
		<fo:list-block provisional-distance-between-starts="{$provisional-distance-between-starts}">
			<fo:list-item>
				<fo:list-item-label end-indent="label-end()">
					<fo:block>
						<xsl:value-of select="$section"/>
					</fo:block>
				</fo:list-item-label>
				<fo:list-item-body start-indent="body-start()">
					<fo:block>
						<xsl:choose>
							<xsl:when test="ns:tab">
								<xsl:apply-templates select="ns:tab[1]/following-sibling::node()"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:apply-templates/>
							</xsl:otherwise>
						</xsl:choose>
					</fo:block>
				</fo:list-item-body>
			</fo:list-item>
		</fo:list-block>
	</xsl:template>

	<xsl:template name="extractSection">
		<xsl:value-of select="ns:tab[1]/preceding-sibling::node()"/>
	</xsl:template>

	<xsl:template name="extractTitle">
		<xsl:choose>
			<xsl:when test="ns:tab">
				<xsl:apply-templates select="ns:tab[1]/following-sibling::node()"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	

	<!-- ========================== -->
	<!-- Source code -->
	<!-- ========================== -->
	<xsl:template match="ns:sourcecode" name="sourcecode">
		<fo:block-container margin-left="0mm">
			<xsl:copy-of select="@id"/>
			<xsl:if test="parent::ns:note">
				<xsl:attribute name="margin-left">
					<xsl:choose>
						<xsl:when test="not(ancestor::ns:table)">
							<xsl:value-of select="$note-body-indent"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$note-body-indent-table"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:attribute>
			</xsl:if>
			<fo:block-container margin-left="0mm">
				<fo:block xsl:use-attribute-sets="sourcecode-style">
					<xsl:variable name="font-size" select="9"/>
					<xsl:if test="$font-size != ''">
						<xsl:attribute name="font-size">
							<xsl:choose>
								<xsl:when test="ancestor::ns:note">
									<xsl:value-of select="$font-size * 0.91"/>pt</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="$font-size"/>pt</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
					</xsl:if>
					<xsl:apply-templates/>
				</fo:block>
				<xsl:apply-templates select="ns:name" mode="presentation"/>
			</fo:block-container>
		</fo:block-container>
	</xsl:template>

	<xsl:template match="ns:sourcecode/text()" priority="2">
		<xsl:variable name="text">
			<xsl:call-template name="add-zero-spaces-equal"/>
		</xsl:variable>
		<xsl:call-template name="add-zero-spaces-java">
			<xsl:with-param name="text" select="$text"/>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="ns:sourcecode/ns:name"/>
	<xsl:template match="ns:sourcecode/ns:name" mode="presentation">
		<xsl:if test="normalize-space() != ''">
			<fo:block xsl:use-attribute-sets="sourcecode-name-style">
				<xsl:apply-templates/>
			</fo:block>
		</xsl:if>
	</xsl:template>
	<!-- ========================== -->
	<!-- END Source code -->
	<!-- ========================== -->

	<!-- ========================== -->
	<!-- Permission, requirement -->
	<!-- ========================== -->
	<xsl:template match="ns:permission">
		<fo:block id="{@id}" xsl:use-attribute-sets="permission-style">
			<xsl:apply-templates select="ns:name" mode="presentation"/>
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:permission/ns:name"/>
	<xsl:template match="ns:permission/ns:name" mode="presentation">
		<xsl:if test="normalize-space() != ''">
			<fo:block xsl:use-attribute-sets="permission-name-style">
				<xsl:apply-templates/>
			</fo:block>
		</xsl:if>
	</xsl:template>

	<xsl:template match="ns:permission/ns:label">
		<fo:block xsl:use-attribute-sets="permission-label-style">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:requirement">
		<fo:block id="{@id}" xsl:use-attribute-sets="requirement-style">
			<xsl:apply-templates select="ns:name" mode="presentation"/>
			<xsl:apply-templates select="ns:label" mode="presentation"/>
			<xsl:apply-templates select="@obligation" mode="presentation"/>
			<xsl:apply-templates select="ns:subject" mode="presentation"/>
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:requirement/ns:name"/>
	<xsl:template match="ns:requirement/ns:name" mode="presentation">
		<xsl:if test="normalize-space() != ''">
			<fo:block xsl:use-attribute-sets="requirement-name-style">
				<xsl:apply-templates/>
			</fo:block>
		</xsl:if>
	</xsl:template>

	<xsl:template match="ns:requirement/ns:label"/>
	<xsl:template match="ns:requirement/ns:label" mode="presentation">
		<fo:block xsl:use-attribute-sets="requirement-label-style">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:requirement/@obligation" mode="presentation">
		<fo:block>
			<fo:inline padding-right="3mm">Obligation</fo:inline>
			<xsl:value-of select="."/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:requirement/ns:subject"/>
	<xsl:template match="ns:requirement/ns:subject" mode="presentation">
		<fo:block xsl:use-attribute-sets="requirement-subject-style">
			<xsl:text>Target Type </xsl:text>
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:requirement/ns:inherit">
		<fo:block xsl:use-attribute-sets="requirement-inherit-style">
			<xsl:text>Dependency </xsl:text>
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:recommendation">
		<fo:block id="{@id}" xsl:use-attribute-sets="recommendation-style">
			<xsl:apply-templates select="ns:name" mode="presentation"/>
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:recommendation/ns:name"/>
	<xsl:template match="ns:recommendation/ns:name" mode="presentation">
		<xsl:if test="normalize-space() != ''">
			<fo:block xsl:use-attribute-sets="recommendation-name-style">
				<xsl:apply-templates/>
			</fo:block>
		</xsl:if>
	</xsl:template>

	<xsl:template match="ns:recommendation/ns:label">
		<fo:block xsl:use-attribute-sets="recommendation-label-style">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:table[@class = 'recommendation' or @class='requirement' or @class='permission']">
		<fo:block-container margin-left="0mm" margin-right="0mm" margin-bottom="12pt">
			<xsl:if test="ancestor::ns:table[@class = 'recommendation' or @class='requirement' or @class='permission']">
				<xsl:attribute name="margin-bottom">0pt</xsl:attribute>
			</xsl:if>
			<fo:block-container margin-left="0mm" margin-right="0mm">
				<fo:table id="{@id}" table-layout="fixed" width="100%">
					<!-- border="1pt solid black" -->
					<xsl:if test="ancestor::ns:table[@class = 'recommendation' or @class='requirement' or @class='permission']">
					</xsl:if>
					<xsl:variable name="simple-table">
						<xsl:call-template name="getSimpleTable"/>
					</xsl:variable>
					<xsl:variable name="cols-count" select="count(xalan:nodeset($simple-table)//tr[1]/td)"/>
					<xsl:if test="$cols-count = 2 and not(ancestor::ns:table)">
						<fo:table-column column-width="30%"/>
						<fo:table-column column-width="70%"/>
					</xsl:if>
					<xsl:apply-templates mode="requirement"/>
				</fo:table>
				<!-- fn processing -->
				<xsl:if test=".//ns:fn">
					<xsl:for-each select="ns:tbody">
						<fo:block font-size="90%" border-bottom="1pt solid black">
							<xsl:call-template name="fn_display"/>
						</fo:block>
					</xsl:for-each>
				</xsl:if>
			</fo:block-container>
		</fo:block-container>
	</xsl:template>

	<xsl:template match="ns:thead" mode="requirement">
		<fo:table-header>
			<xsl:apply-templates mode="requirement"/>
		</fo:table-header>
	</xsl:template>

	<xsl:template match="ns:tbody" mode="requirement">
		<fo:table-body>
			<xsl:apply-templates mode="requirement"/>
		</fo:table-body>
	</xsl:template>

	<xsl:template match="ns:tr" mode="requirement">
		<fo:table-row height="7mm" border-bottom="0.5pt solid grey">
			<xsl:if test="parent::ns:thead">
				<xsl:attribute name="background-color">rgb(33, 55, 92)</xsl:attribute>
			</xsl:if>
			<xsl:if test="starts-with(ns:td[1], 'Requirement ')">
				<xsl:attribute name="background-color">rgb(252, 246, 222)</xsl:attribute>
			</xsl:if>
			<xsl:if test="starts-with(ns:td[1], 'Recommendation ')">
				<xsl:attribute name="background-color">rgb(233, 235, 239)</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates mode="requirement"/>
		</fo:table-row>
	</xsl:template>

	<xsl:template match="ns:th" mode="requirement">
		<fo:table-cell text-align="{@align}" display-align="center" padding="1mm" padding-left="2mm">
			<xsl:attribute name="text-align">
				<xsl:choose>
					<xsl:when test="@align">
						<xsl:value-of select="@align"/>
					</xsl:when>
					<xsl:otherwise>left</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<xsl:if test="@colspan">
				<xsl:attribute name="number-columns-spanned">
					<xsl:value-of select="@colspan"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="@rowspan">
				<xsl:attribute name="number-rows-spanned">
					<xsl:value-of select="@rowspan"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:call-template name="display-align"/>
			<fo:block>
				<xsl:apply-templates/>
			</fo:block>
		</fo:table-cell>
	</xsl:template>

	<xsl:template match="ns:td" mode="requirement">
		<fo:table-cell text-align="{@align}" display-align="center" padding="1mm" padding-left="2mm">
			<xsl:if test="ns:table[@class = 'recommendation' or @class='requirement' or @class='permission']">
				<xsl:attribute name="padding">0mm</xsl:attribute>
				<xsl:attribute name="padding-left">0mm</xsl:attribute>
			</xsl:if>
			<xsl:attribute name="text-align">
				<xsl:choose>
					<xsl:when test="@align">
						<xsl:value-of select="@align"/>
					</xsl:when>
					<xsl:otherwise>left</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<xsl:if test="following-sibling::ns:td and not(preceding-sibling::ns:td)">
				<xsl:attribute name="font-weight">bold</xsl:attribute>
			</xsl:if>
			<xsl:if test="@colspan">
				<xsl:attribute name="number-columns-spanned">
					<xsl:value-of select="@colspan"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:if test="@rowspan">
				<xsl:attribute name="number-rows-spanned">
					<xsl:value-of select="@rowspan"/>
				</xsl:attribute>
			</xsl:if>
			<xsl:call-template name="display-align"/>
			<!-- 2nd line and below -->
			<fo:block>
				<xsl:apply-templates/>
			</fo:block>
		</fo:table-cell>
	</xsl:template>

	<xsl:template match="ns:p[@class='RecommendationTitle' or @class = 'RecommendationTestTitle']" priority="2">
		<fo:block font-size="11pt" color="rgb(237, 193, 35)">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:p2[ancestor::ns:table[@class = 'recommendation' or @class='requirement' or @class='permission']]">
		<fo:block>
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<!-- ========================== -->
	<!-- END Permission, requirement -->
	<!-- ========================== -->


	<!-- ======================== -->
	<!-- Example, term example -->
	<!-- ======================== -->
	<xsl:template match="ns:termexample">
		<fo:block id="{@id}" xsl:use-attribute-sets="termexample-style">
			<xsl:apply-templates select="ns:name" mode="presentation"/>
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:termexample/ns:name"/>
	<xsl:template match="ns:termexample/ns:name" mode="presentation">
		<xsl:if test="normalize-space() != ''">
			<fo:inline xsl:use-attribute-sets="termexample-name-style">
				<xsl:apply-templates/>
			</fo:inline>
		</xsl:if>
	</xsl:template>

	<xsl:template match="ns:termexample/ns:p">
		<fo:inline>
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>

	<xsl:template match="ns:example">
		<fo:block id="{@id}" xsl:use-attribute-sets="example-style">
			<xsl:apply-templates select="ns:name" mode="presentation"/>
			<xsl:variable name="element">
								
				inline
				<xsl:if test=".//ns:table">block</xsl:if>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="contains(normalize-space($element), 'block')">
					<fo:block xsl:use-attribute-sets="example-body-style">
						<xsl:apply-templates/>
					</fo:block>
				</xsl:when>
				<xsl:otherwise>
					<fo:inline>
						<xsl:apply-templates/>
					</fo:inline>
				</xsl:otherwise>
			</xsl:choose>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:example/ns:name"/>
	<xsl:template match="ns:example/ns:name" mode="presentation">
		<xsl:variable name="element">
			inline
			<xsl:if test="following-sibling::*[1][local-name() = 'table']">block</xsl:if>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="ancestor::ns:appendix">
				<fo:inline>
					<xsl:apply-templates/>
				</fo:inline>
			</xsl:when>
			<xsl:when test="contains(normalize-space($element), 'block')">
				<fo:block xsl:use-attribute-sets="example-name-style">
					<xsl:apply-templates/>
				</fo:block>
			</xsl:when>
			<xsl:otherwise>
				<fo:inline xsl:use-attribute-sets="example-name-style">
					<xsl:apply-templates/>
				</fo:inline>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="ns:example/ns:p">
		<xsl:variable name="num">
			<xsl:number/>
		</xsl:variable>
		<xsl:variable name="element">
			<xsl:choose>
				<xsl:when test="$num = 1">inline</xsl:when>
				<xsl:otherwise>block</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="normalize-space($element) = 'block'">
				<fo:block xsl:use-attribute-sets="example-p-style">
					<xsl:apply-templates/>
				</fo:block>
			</xsl:when>
			<xsl:otherwise>
				<fo:inline xsl:use-attribute-sets="example-p-style">
					<xsl:apply-templates/>
				</fo:inline>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- ======================== -->
	<!-- END Example, term example -->
	<!-- ======================== -->

	<xsl:template match="ns:termsource" name="termsource">
		<fo:block xsl:use-attribute-sets="termsource-style">
			<!-- Example: [SOURCE: ISO 5127:2017, 3.1.6.02] -->
			<xsl:variable name="termsource_text">
				<xsl:apply-templates/>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="starts-with(normalize-space($termsource_text), '[')">
					<xsl:copy-of select="$termsource_text"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>[</xsl:text>
					<xsl:copy-of select="$termsource_text"/>
					<xsl:text>]</xsl:text>
				</xsl:otherwise>
			</xsl:choose>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:termsource/text()">
		<xsl:if test="normalize-space() != ''">
			<xsl:value-of select="."/>
		</xsl:if>
	</xsl:template>

	<xsl:variable name="localized.source">
		<xsl:call-template name="getLocalizedString">
			<xsl:with-param name="key">source</xsl:with-param>
		</xsl:call-template>
	</xsl:variable>
	<xsl:template match="ns:origin">
		<fo:basic-link internal-destination="{@bibitemid}" fox:alt-text="{@citeas}">
			<xsl:if test="normalize-space(@citeas) = ''">
				<xsl:attribute name="fox:alt-text">
					<xsl:value-of select="@bibitemid"/>
				</xsl:attribute>
			</xsl:if>
			<fo:inline>
				<xsl:value-of select="$localized.source"/>
				<xsl:text>: </xsl:text>
			</fo:inline>
			<fo:inline xsl:use-attribute-sets="origin-style">
				<xsl:apply-templates/>
			</fo:inline>
		</fo:basic-link>
	</xsl:template>

	<xsl:template match="ns:modification/ns:p">
		<fo:inline>
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>

	<xsl:template match="ns:modification/text()">
		<xsl:if test="normalize-space() != ''">
			<xsl:value-of select="."/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="ns:quote">
		<fo:block-container margin-left="0mm">
			<xsl:if test="parent::ns:note">
				<xsl:if test="not(ancestor::ns:table)">
					<xsl:attribute name="margin-left">5mm</xsl:attribute>
				</xsl:if>
			</xsl:if>
			<fo:block-container margin-left="0mm">
				<fo:block xsl:use-attribute-sets="quote-style">
					<xsl:apply-templates select="./node()[not(local-name() = 'author') and not(local-name() = 'source')]"/>
					<!-- process all nested nodes, except author and source -->
				</fo:block>
				<xsl:if test="ns:author or ns:source">
					<fo:block xsl:use-attribute-sets="quote-source-style">
						<!-- — ISO, ISO 7301:2011, Clause 1 -->
						<xsl:apply-templates select="ns:author"/>
						<xsl:apply-templates select="ns:source"/>
					</fo:block>
				</xsl:if>
			</fo:block-container>
		</fo:block-container>
	</xsl:template>

	<xsl:template match="ns:source">
		<xsl:if test="../ns:author">
			<xsl:text>, </xsl:text>
		</xsl:if>
		<fo:basic-link internal-destination="{@bibitemid}" fox:alt-text="{@citeas}">
			<xsl:apply-templates/>
		</fo:basic-link>
	</xsl:template>

	<xsl:template match="ns:author">
		<xsl:text>— </xsl:text>
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="ns:eref">
		<xsl:variable name="bibitemid">
			<xsl:choose>
				<xsl:when test="//ns:bibitem[@hidden='true' and @id = current()/@bibitemid]"/>
				<xsl:when test="//ns:references[@hidden='true']/ns:bibitem[@id = current()/@bibitemid]"/>
				<xsl:otherwise>
					<xsl:value-of select="@bibitemid"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="normalize-space($bibitemid) != ''">
				<fo:inline xsl:use-attribute-sets="eref-style">
					<xsl:if test="@type = 'footnote'">
						<xsl:attribute name="keep-together.within-line">always</xsl:attribute>
						<xsl:attribute name="font-size">80%</xsl:attribute>
						<xsl:attribute name="keep-with-previous.within-line">always</xsl:attribute>
						<xsl:attribute name="vertical-align">super</xsl:attribute>
					</xsl:if>
					<fo:basic-link internal-destination="{@bibitemid}" fox:alt-text="{@citeas}">
						<xsl:if test="normalize-space(@citeas) = ''">
							<xsl:attribute name="fox:alt-text">
								<xsl:value-of select="."/>
							</xsl:attribute>
						</xsl:if>
						<xsl:if test="@type = 'inline'">
							
						</xsl:if>
						<xsl:apply-templates/>
					</fo:basic-link>
				</fo:inline>
			</xsl:when>
			<xsl:otherwise>
				<fo:inline>
					<xsl:apply-templates/>
				</fo:inline>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="ns:tab">
		<!-- zero-space char -->
		<xsl:variable name="depth">
			<xsl:call-template name="getLevel">
				<xsl:with-param name="depth" select="../@depth"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:variable name="padding">
			<xsl:choose>
				<xsl:when test="$depth = 2">3</xsl:when>
				<xsl:otherwise>4</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="padding-right">
			<xsl:choose>
				<xsl:when test="normalize-space($padding) = ''">0</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="normalize-space($padding)"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="language" select="//ns:bibdata//ns:language"/>
		<xsl:choose>
			<xsl:when test="../../@inline-header = 'true'">
				<fo:inline font-size="90%">
					<xsl:call-template name="insertNonBreakSpaces">
						<xsl:with-param name="count" select="$padding-right"/>
					</xsl:call-template>
				</fo:inline>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="direction">
					<xsl:if test="$lang = 'ar'">
						<xsl:value-of select="$RLM"/>
					</xsl:if>
				</xsl:variable>
				<fo:inline padding-right="{$padding-right}mm">
					<xsl:value-of select="$direction"/>​</fo:inline>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="insertNonBreakSpaces">
		<xsl:param name="count"/>
		<xsl:if test="$count &gt; 0">
			<xsl:text> </xsl:text>
			<xsl:call-template name="insertNonBreakSpaces">
				<xsl:with-param name="count" select="$count - 1"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

	

	<xsl:template match="/*/ns:sections/*" priority="2">
		<fo:block>
			<xsl:call-template name="setId"/>
			<xsl:variable name="pos">
				<xsl:number count="*"/>
			</xsl:variable>
			<xsl:if test="$pos &gt;= 2">
				<xsl:attribute name="space-before">18pt</xsl:attribute>
			</xsl:if>
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="//*[contains(local-name(), '-standard')]/ns:preface/*" priority="2">
		<fo:block break-after="page"/>
		<fo:block>
			<xsl:call-template name="setId"/>
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:clause">
		<fo:block>
			<xsl:call-template name="setId"/>
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	

	<xsl:template match="ns:annex">
		<fo:block break-after="page"/>
		<fo:block id="{@id}">
			
		</fo:block>
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="ns:review">
	</xsl:template>

	<xsl:template match="ns:name/text()">
		<!-- 0xA0 to space replacement -->
		<xsl:value-of select="java:replaceAll(java:java.lang.String.new(.),' ',' ')"/>
	</xsl:template>

	<!-- ================== -->
	<!-- List processing -->
	<!-- ================== -->
	<xsl:template match="ns:ul | ns:ol">
		<xsl:choose>
			<xsl:when test="parent::ns:note or parent::ns:termnote">
				<fo:block-container>
					<xsl:attribute name="margin-left">
						<xsl:choose>
							<xsl:when test="not(ancestor::ns:table)">
								<xsl:value-of select="$note-body-indent"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$note-body-indent-table"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:attribute>
					<fo:block-container margin-left="0mm">
						<fo:block>
							<xsl:apply-templates select="." mode="ul_ol"/>
						</fo:block>
					</fo:block-container>
				</fo:block-container>
			</xsl:when>
			<xsl:otherwise>
				<fo:block>
					<xsl:apply-templates select="." mode="ul_ol"/>
				</fo:block>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template match="ns:ul | ns:ol" mode="ul_ol">
		<fo:list-block provisional-distance-between-starts="7mm" margin-top="8pt">
			<xsl:apply-templates/>
		</fo:list-block>
		<xsl:for-each select="./ns:note">
			<xsl:call-template name="note"/>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="ns:ul/ns:note |  ns:ol/ns:note | ns:ul/ns:li/ns:note |  ns:ol/ns:li/ns:note" priority="2"/>
	<xsl:template match="ns:li">
		<fo:list-item id="{@id}">
			<fo:list-item-label end-indent="label-end()">
				<fo:block>
					<xsl:call-template name="getListItemFormat"/>
				</fo:block>
			</fo:list-item-label>
			<fo:list-item-body start-indent="body-start()">
				<fo:block>
					<xsl:apply-templates/>
					<xsl:for-each select="./ns:note">
						<xsl:call-template name="note"/>
					</xsl:for-each>
				</fo:block>
			</fo:list-item-body>
		</fo:list-item>
	</xsl:template>
	
	<xsl:template name="getListItemFormat">
		<xsl:choose>
			<xsl:when test="local-name(..) = 'ul'">—</xsl:when>
			<!-- dash -->
			<xsl:otherwise>
				<!-- for ordered lists -->
				<xsl:choose>
					<xsl:when test="../@type = 'arabic'">
						<xsl:number format="1." lang="en"/>
					</xsl:when>
					<xsl:when test="../@type = 'alphabet'">
						<xsl:number format="a)" lang="en"/>
					</xsl:when>
					<xsl:when test="../@type = 'alphabet_upper'">
						<xsl:number format="A." lang="en"/>
					</xsl:when>
					<xsl:when test="../@type = 'roman'">
						<xsl:number format="i)"/>
					</xsl:when>
					<xsl:when test="../@type = 'roman_upper'">
						<xsl:number format="I."/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:number format="a)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	
	<!-- ================== -->
	<!-- END List processing -->
	<!-- ================== -->


	<xsl:variable name="index" select="document($external_index)"/>
	<xsl:variable name="dash" select="'–'"/>
	<xsl:variable name="bookmark_in_fn">
		<xsl:for-each select="//ns:bookmark[ancestor::ns:fn]">
			<bookmark>
				<xsl:value-of select="@id"/>
			</bookmark>
		</xsl:for-each>
	</xsl:variable>
	

	<xsl:template match="ns:bookmark" name="bookmark">
		<fo:inline id="{@id}" font-size="1pt"/>
	</xsl:template>


	<xsl:template match="ns:errata">
		<!-- <row>
					<date>05-07-2013</date>
					<type>Editorial</type>
					<change>Changed CA-9 Priority Code from P1 to P2 in <xref target="tabled2"/>.</change>
					<pages>D-3</pages>
				</row>
		-->
		<fo:table table-layout="fixed" width="100%" font-size="10pt" border="1pt solid black">
			<fo:table-column column-width="20mm"/>
			<fo:table-column column-width="23mm"/>
			<fo:table-column column-width="107mm"/>
			<fo:table-column column-width="15mm"/>
			<fo:table-body>
				<fo:table-row text-align="center" font-weight="bold" background-color="black" color="white">
					<fo:table-cell border="1pt solid black">
						<fo:block>Date</fo:block>
					</fo:table-cell>
					<fo:table-cell border="1pt solid black">
						<fo:block>Type</fo:block>
					</fo:table-cell>
					<fo:table-cell border="1pt solid black">
						<fo:block>Change</fo:block>
					</fo:table-cell>
					<fo:table-cell border="1pt solid black">
						<fo:block>Pages</fo:block>
					</fo:table-cell>
				</fo:table-row>
				<xsl:apply-templates/>
			</fo:table-body>
		</fo:table>
	</xsl:template>

	<xsl:template match="ns:errata/ns:row">
		<fo:table-row>
			<xsl:apply-templates/>
		</fo:table-row>
	</xsl:template>

	<xsl:template match="ns:errata/ns:row/*">
		<fo:table-cell border="1pt solid black" padding-left="1mm" padding-top="0.5mm">
			<fo:block>
				<xsl:apply-templates/>
			</fo:block>
		</fo:table-cell>
	</xsl:template>



	<!-- ============================ -->
	<!-- Bibliography -->
	<!-- ============================ -->
	
	<xsl:template match="ns:references[@hidden='true']" priority="3"/>
	<xsl:template match="ns:bibitem[@hidden='true']" priority="3"/>
	
	<xsl:template match="ns:references[@normative='true']">
		<fo:block id="{@id}">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:references[not(@normative='true')]">
		<fo:block break-after="page"/>
		<fo:block id="{@id}">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:bibitem">
		<fo:block id="{@id}" margin-bottom="6pt">
			<xsl:call-template name="processBibitem"/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:bibitem/ns:note" priority="2">
		<fo:footnote>
			<xsl:variable name="number">
				<xsl:number level="any" count="ns:bibitem/ns:note"/>
			</xsl:variable>
			<fo:inline font-size="8pt" keep-with-previous.within-line="always" baseline-shift="30%">
				<fo:basic-link internal-destination="{generate-id()}" fox:alt-text="footnote {$number}">
					<xsl:value-of select="$number"/>
					<xsl:text>)</xsl:text>
				</fo:basic-link>
			</fo:inline>
			<fo:footnote-body>
				<fo:block font-size="10pt" margin-bottom="4pt" start-indent="0pt">
					<fo:inline id="{generate-id()}" keep-with-next.within-line="always" alignment-baseline="hanging" padding-right="3mm">
						<xsl:value-of select="$number"/>
						<xsl:text>)</xsl:text>
					</fo:inline>
					<xsl:apply-templates/>
				</fo:block>
			</fo:footnote-body>
		</fo:footnote>
	</xsl:template>

	<!-- Example: [1] ISO 9:1995, Information and documentation – Transliteration of Cyrillic characters into Latin characters – Slavic and non-Slavic languages -->
	<xsl:template match="ns:references[not(@normative='true')]/ns:bibitem">
		<fo:list-block margin-bottom="6pt" provisional-distance-between-starts="12mm">
			<fo:list-item>
				<fo:list-item-label end-indent="label-end()">
					<fo:block>
						<fo:inline id="{@id}">
							<xsl:number format="[1]"/>
						</fo:inline>
					</fo:block>
				</fo:list-item-label>
				<fo:list-item-body start-indent="body-start()">
					<fo:block>
						<xsl:call-template name="processBibitem"/>
					</fo:block>
				</fo:list-item-body>
			</fo:list-item>
		</fo:list-block>
	</xsl:template>

	<xsl:template match="ns:bibitem/ns:title">
		<fo:inline font-style="italic">
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>

	<xsl:template name="processBibitem">
		<xsl:variable name="docidentifier">
			<xsl:if test="ns:docidentifier">
				<xsl:choose>
					<xsl:when test="ns:docidentifier/@type = 'metanorma'"/>
					<xsl:otherwise>
						<xsl:value-of select="ns:docidentifier"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:if>
		</xsl:variable>
		<xsl:value-of select="$docidentifier"/>
		<xsl:apply-templates select="ns:note"/>
		<xsl:if test="normalize-space($docidentifier) != ''">, </xsl:if>
		<xsl:choose>
			<xsl:when test="ns:title[@type = 'main' and @language = $lang]">
				<xsl:apply-templates select="ns:title[@type = 'main' and @language = $lang]"/>
			</xsl:when>
			<xsl:when test="ns:title[@type = 'main' and @language = 'en']">
				<xsl:apply-templates select="ns:title[@type = 'main' and @language = 'en']"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates select="ns:title"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:apply-templates select="ns:formattedref"/>
		
	</xsl:template>

	<xsl:template name="processBibitemDocId">
		<xsl:variable name="_doc_ident" select="ns:docidentifier[not(@type = 'DOI' or @type = 'metanorma' or @type = 'ISSN' or @type = 'ISBN' or @type = 'rfc-anchor')]"/>
		<xsl:choose>
			<xsl:when test="normalize-space($_doc_ident) != ''">
				<xsl:value-of select="$_doc_ident"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="ns:docidentifier[not(@type = 'metanorma')]"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<!-- ============================ -->
	<!-- END Bibliography -->
	<!-- ============================ -->
	
	<xsl:template match="ns:pagebreak">
		<fo:block break-after="page"/>
		<fo:block>&#xA0;</fo:block>
		<fo:block break-after="page"/>
	</xsl:template>

	<!-- =================== -->
	<!-- Index processing -->
	<!-- =================== -->
	<xsl:template match="ns:indexsect"/>
	<xsl:template match="ns:indexsect" mode="index">
		<fo:page-sequence master-reference="index" force-page-count="no-force">
			<xsl:variable name="header-title">
				<xsl:choose>
					<xsl:when test="./ns:title[1]/ns:tab">
						<xsl:apply-templates select="./ns:title[1]/ns:tab[1]/following-sibling::node()" mode="header"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:apply-templates select="./ns:title[1]" mode="header"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:call-template name="insertHeaderFooter">
				<xsl:with-param name="header-title" select="$header-title"/>
			</xsl:call-template>
			<fo:flow flow-name="xsl-region-body">
				<fo:block id="{@id}" span="all">
					<xsl:apply-templates select="ns:title"/>
				</fo:block>
				<fo:block>
					<xsl:apply-templates select="not(ns:title)"/>
				</fo:block>
			</fo:flow>
		</fo:page-sequence>
	</xsl:template>

	<xsl:template match="ns:indexsect/ns:title" priority="4">
		<fo:block font-size="16pt" font-weight="bold" margin-bottom="84pt">
			<!-- Index -->
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:indexsect/ns:clause/ns:title" priority="4">
		<!-- Letter A, B, C, ... -->
		<fo:block font-size="10pt" font-weight="bold" margin-bottom="3pt" keep-with-next="always">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:indexsect//ns:li/text()">
		<!-- to split by '_' and other chars -->
		<xsl:call-template name="add-zero-spaces-java"/>
	</xsl:template>
	
	<xsl:template match="ns:indexsect/ns:clause" priority="4">
		<xsl:apply-templates/>
		<fo:block>
			<xsl:if test="following-sibling::ns:clause">
				<fo:block> </fo:block>
			</xsl:if>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:indexsect//ns:ul" priority="4">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="ns:indexsect//ns:li" priority="4">
		<xsl:variable name="level" select="count(ancestor::ns:ul)"/>
		<fo:block start-indent="{5 * $level}mm" text-indent="-5mm">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>
	<!-- =================== -->
	<!-- Index processing -->
	<!-- =================== -->


	

	<xsl:template name="renderDate">
		<xsl:if test="normalize-space(ns:on) != ''">
			<xsl:value-of select="ns:on"/>
		</xsl:if>
		<xsl:if test="normalize-space(ns:from) != ''">
			<xsl:value-of select="concat(ns:from, '–', ns:to)"/>
		</xsl:if>
	</xsl:template>

	<xsl:template match="ns:name/ns:initial/text()" mode="strip">
		<xsl:value-of select="translate(.,'. ','')"/>
	</xsl:template>

	<xsl:template match="ns:name/ns:forename/text()" mode="strip">
		<xsl:value-of select="substring(.,1,1)"/>
	</xsl:template>

	<xsl:template match="ns:title" mode="title">
		<fo:inline>
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>

	<!-- ======================= -->
	<!-- Forms -->
	<!-- ======================= -->
	<xsl:template match="ns:form">
		<fo:block>
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="ns:form//ns:label">
		<fo:inline>
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>

	<xsl:template match="ns:form//ns:input[@type = 'text' or @type = 'date' or @type = 'file' or @type = 'password']">
		<fo:inline>
			<xsl:call-template name="text_input"/>
		</fo:inline>
	</xsl:template>

	<xsl:template name="text_input">
		<xsl:variable name="count">
			<xsl:choose>
				<xsl:when test="normalize-space(@maxlength) != ''">
					<xsl:value-of select="@maxlength"/>
				</xsl:when>
				<xsl:when test="normalize-space(@size) != ''">
					<xsl:value-of select="@size"/>
				</xsl:when>
				<xsl:otherwise>10</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:call-template name="repeat">
			<xsl:with-param name="char" select="'_'"/>
			<xsl:with-param name="count" select="$count"/>
		</xsl:call-template>
		<xsl:text> </xsl:text>
	</xsl:template>

	<xsl:template match="ns:form//ns:input[@type = 'button']">
		<xsl:variable name="caption">
			<xsl:choose>
				<xsl:when test="normalize-space(@value) != ''">
					<xsl:value-of select="@value"/>
				</xsl:when>
				<xsl:otherwise>BUTTON</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<fo:inline>[<xsl:value-of select="$caption"/>]</fo:inline>
	</xsl:template>

	<xsl:template match="ns:form//ns:input[@type = 'checkbox']">
		<fo:inline padding-right="1mm">
			<fo:instream-foreign-object fox:alt-text="Box" baseline-shift="-10%">
				<xsl:attribute name="height">3.5mm</xsl:attribute>
				<xsl:attribute name="content-width">100%</xsl:attribute>
				<xsl:attribute name="content-width">scale-down-to-fit</xsl:attribute>
				<xsl:attribute name="scaling">uniform</xsl:attribute>
				<svg xmlns="http://www.w3.org/2000/svg" width="80" height="80">
					<polyline points="0,0 80,0 80,80 0,80 0,0" stroke="black" stroke-width="5" fill="white"/>
				</svg>
			</fo:instream-foreign-object>
		</fo:inline>
	</xsl:template>

	<xsl:template match="ns:form//ns:input[@type = 'radio']">
		<fo:inline padding-right="1mm">
			<fo:instream-foreign-object fox:alt-text="Box" baseline-shift="-10%">
				<xsl:attribute name="height">3.5mm</xsl:attribute>
				<xsl:attribute name="content-width">100%</xsl:attribute>
				<xsl:attribute name="content-width">scale-down-to-fit</xsl:attribute>
				<xsl:attribute name="scaling">uniform</xsl:attribute>
				<svg xmlns="http://www.w3.org/2000/svg" width="80" height="80">
					<circle cx="40" cy="40" r="30" stroke="black" stroke-width="5" fill="white"/>
					<circle cx="40" cy="40" r="15" stroke="black" stroke-width="5" fill="white"/>
				</svg>
			</fo:instream-foreign-object>
		</fo:inline>
	</xsl:template>

	<xsl:template match="ns:form//ns:select">
		<fo:inline>
			<xsl:call-template name="text_input"/>
		</fo:inline>
	</xsl:template>

	<xsl:template match="ns:form//ns:textarea">
		<fo:block-container border="1pt solid black" width="50%">
			<fo:block> </fo:block>
		</fo:block-container>
	</xsl:template>
	<!-- ======================= -->
	<!-- END Forms -->
	<!-- ======================= -->
	

	<!-- ======================= -->
	<!-- Functions (named templates) -->
	<!-- ======================= -->
	
	<xsl:template name="printEdition">
		<xsl:variable name="edition" select="normalize-space(/*/ns:bibdata/ns:edition)"/>
		<xsl:text> </xsl:text>
		<xsl:choose>
			<xsl:when test="number($edition) = $edition">
				<xsl:call-template name="number-to-words">
					<xsl:with-param name="number" select="$edition"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:when test="$edition != ''">
				<xsl:value-of select="$edition"/>
			</xsl:when>
		</xsl:choose>
		<xsl:variable name="title-edition">
			<xsl:call-template name="getTitle">
				<xsl:with-param name="name" select="'title-edition'"/>
			</xsl:call-template>
		</xsl:variable>
		<xsl:if test="$edition != ''">
			<xsl:text> </xsl:text>
			<xsl:value-of select="java:toLowerCase(java:java.lang.String.new($title-edition))"/>
		</xsl:if>
	</xsl:template>

	<xsl:template name="printTitlePartFr">
		<xsl:variable name="part-fr" select="/*/ns:bibdata/ns:title[@language = 'fr' and @type = 'title-part']"/>
		<xsl:if test="normalize-space($part-fr) != ''">
			<xsl:if test="$part != ''">
				<xsl:text> — </xsl:text>
				<xsl:value-of select="java:replaceAll(java:java.lang.String.new($titles/title-part[@lang='fr']),'#',$part)"/>
			</xsl:if>
			<xsl:value-of select="$part-fr"/>
		</xsl:if>
	</xsl:template>

	<xsl:template name="printTitlePartEn">
		<xsl:variable name="part-en" select="/*/ns:bibdata/ns:title[@language = 'en' and @type = 'title-part']"/>
		<xsl:if test="normalize-space($part-en) != ''">
			<xsl:if test="$part != ''">
				<xsl:text> — </xsl:text>
				<fo:block font-weight="normal" margin-top="6pt">
					<xsl:value-of select="java:replaceAll(java:java.lang.String.new($titles/title-part[@lang='en']),'#',$part)"/>
				</fo:block>
			</xsl:if>
			<xsl:value-of select="$part-en"/>
		</xsl:if>
	</xsl:template>
	
	<xsl:variable name="bibdata">
		<xsl:copy-of select="//*[contains(local-name(), '-standard')]/ns:bibdata"/>
		<xsl:copy-of select="//*[contains(local-name(), '-standard')]/ns:localized-strings"/>
	</xsl:variable>
	
	<xsl:template name="getLang">
		<xsl:variable name="language_current" select="normalize-space(//ns:bibdata//ns:language[@current = 'true'])"/>
		<xsl:variable name="language_current_2" select="normalize-space(xalan:nodeset($bibdata)//ns:bibdata//ns:language[@current = 'true'])"/>
		<xsl:variable name="language">
			<xsl:choose>
				<xsl:when test="$language_current != ''">
					<xsl:value-of select="$language_current"/>
				</xsl:when>
				<xsl:when test="$language_current_2 != ''">
					<xsl:value-of select="$language_current_2"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="//ns:bibdata//ns:language"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$language = 'English'">en</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$language"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="capitalizeWords">
		<xsl:param name="str"/>
		<xsl:variable name="str2" select="translate($str, '-', ' ')"/>
		<xsl:choose>
			<xsl:when test="contains($str2, ' ')">
				<xsl:variable name="substr" select="substring-before($str2, ' ')"/>
				<xsl:call-template name="capitalize">
					<xsl:with-param name="str" select="$substr"/>
				</xsl:call-template>
				<xsl:text> </xsl:text>
				<xsl:call-template name="capitalizeWords">
					<xsl:with-param name="str" select="substring-after($str2, ' ')"/>
				</xsl:call-template>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="capitalize">
					<xsl:with-param name="str" select="$str2"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="capitalize">
		<xsl:param name="str"/>
		<xsl:value-of select="java:toUpperCase(java:java.lang.String.new(substring($str, 1, 1)))"/>
		<xsl:value-of select="substring($str, 2)"/>
	</xsl:template>
	
	<xsl:template name="convertDate">
		<xsl:param name="date"/>
		<xsl:param name="format" select="'short'"/>
		<xsl:variable name="year" select="substring($date, 1, 4)"/>
		<xsl:variable name="month" select="substring($date, 6, 2)"/>
		<xsl:variable name="day" select="substring($date, 9, 2)"/>
		<xsl:variable name="monthStr">
			<xsl:choose>
				<xsl:when test="$month = '01'">January</xsl:when>
				<xsl:when test="$month = '02'">February</xsl:when>
				<xsl:when test="$month = '03'">March</xsl:when>
				<xsl:when test="$month = '04'">April</xsl:when>
				<xsl:when test="$month = '05'">May</xsl:when>
				<xsl:when test="$month = '06'">June</xsl:when>
				<xsl:when test="$month = '07'">July</xsl:when>
				<xsl:when test="$month = '08'">August</xsl:when>
				<xsl:when test="$month = '09'">September</xsl:when>
				<xsl:when test="$month = '10'">October</xsl:when>
				<xsl:when test="$month = '11'">November</xsl:when>
				<xsl:when test="$month = '12'">December</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="result">
			<xsl:choose>
				<xsl:when test="$format = 'ddMMyyyy'">
					<xsl:if test="$day != ''">
						<xsl:value-of select="number($day)"/>
					</xsl:if>
					<xsl:text> </xsl:text>
					<xsl:value-of select="normalize-space(concat($monthStr, ' ' , $year))"/>
				</xsl:when>
				<xsl:when test="$format = 'ddMM'">
					<xsl:if test="$day != ''">
						<xsl:value-of select="number($day)"/>
					</xsl:if>
					<xsl:text> </xsl:text>
					<xsl:value-of select="$monthStr"/>
				</xsl:when>
				<xsl:when test="$format = 'short' or $day = ''">
					<xsl:value-of select="normalize-space(concat($monthStr, ' ', $year))"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="normalize-space(concat($monthStr, ' ', $day, ', ' , $year))"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="$result"/>
	</xsl:template>

	<xsl:template name="convertDateLocalized">
		<xsl:param name="date"/>
		<xsl:param name="format" select="'short'"/>
		<xsl:variable name="year" select="substring($date, 1, 4)"/>
		<xsl:variable name="month" select="substring($date, 6, 2)"/>
		<xsl:variable name="day" select="substring($date, 9, 2)"/>
		<xsl:variable name="monthStr">
			<xsl:choose>
				<xsl:when test="$month = '01'">
					<xsl:call-template name="getLocalizedString">
						<xsl:with-param name="key">month_january</xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$month = '02'">
					<xsl:call-template name="getLocalizedString">
						<xsl:with-param name="key">month_february</xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$month = '03'">
					<xsl:call-template name="getLocalizedString">
						<xsl:with-param name="key">month_march</xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$month = '04'">
					<xsl:call-template name="getLocalizedString">
						<xsl:with-param name="key">month_april</xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$month = '05'">
					<xsl:call-template name="getLocalizedString">
						<xsl:with-param name="key">month_may</xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$month = '06'">
					<xsl:call-template name="getLocalizedString">
						<xsl:with-param name="key">month_june</xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$month = '07'">
					<xsl:call-template name="getLocalizedString">
						<xsl:with-param name="key">month_july</xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$month = '08'">
					<xsl:call-template name="getLocalizedString">
						<xsl:with-param name="key">month_august</xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$month = '09'">
					<xsl:call-template name="getLocalizedString">
						<xsl:with-param name="key">month_september</xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$month = '10'">
					<xsl:call-template name="getLocalizedString">
						<xsl:with-param name="key">month_october</xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$month = '11'">
					<xsl:call-template name="getLocalizedString">
						<xsl:with-param name="key">month_november</xsl:with-param>
					</xsl:call-template>
				</xsl:when>
				<xsl:when test="$month = '12'">
					<xsl:call-template name="getLocalizedString">
						<xsl:with-param name="key">month_december</xsl:with-param>
					</xsl:call-template>
				</xsl:when>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="result">
			<xsl:choose>
				<xsl:when test="$format = 'ddMMyyyy'">
					<xsl:if test="$day != ''">
						<xsl:value-of select="number($day)"/>
					</xsl:if>
					<xsl:text> </xsl:text>
					<xsl:value-of select="normalize-space(concat($monthStr, ' ' , $year))"/>
				</xsl:when>
				<xsl:when test="$format = 'ddMM'">
					<xsl:if test="$day != ''">
						<xsl:value-of select="number($day)"/>
					</xsl:if>
					<xsl:text> </xsl:text>
					<xsl:value-of select="$monthStr"/>
				</xsl:when>
				<xsl:when test="$format = 'short' or $day = ''">
					<xsl:value-of select="normalize-space(concat($monthStr, ' ', $year))"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="normalize-space(concat($monthStr, ' ', $day, ', ' , $year))"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:value-of select="$result"/>
	</xsl:template>

	<xsl:template name="insertKeywords">
		<xsl:param name="sorting" select="'true'"/>
		<xsl:param name="charAtEnd" select="'.'"/>
		<xsl:param name="charDelim" select="', '"/>
		<xsl:choose>
			<xsl:when test="$sorting = 'true' or $sorting = 'yes'">
				<xsl:for-each select="//*[contains(local-name(), '-standard')]/ns:bibdata//ns:keyword">
					<xsl:sort data-type="text" order="ascending"/>
					<xsl:call-template name="insertKeyword">
						<xsl:with-param name="charAtEnd" select="$charAtEnd"/>
						<xsl:with-param name="charDelim" select="$charDelim"/>
					</xsl:call-template>
				</xsl:for-each>
			</xsl:when>
			<xsl:otherwise>
				<xsl:for-each select="//*[contains(local-name(), '-standard')]/ns:bibdata//ns:keyword">
					<xsl:call-template name="insertKeyword">
						<xsl:with-param name="charAtEnd" select="$charAtEnd"/>
						<xsl:with-param name="charDelim" select="$charDelim"/>
					</xsl:call-template>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="insertKeyword">
		<xsl:param name="charAtEnd"/>
		<xsl:param name="charDelim"/>
		<xsl:apply-templates/>
		<xsl:choose>
			<xsl:when test="position() != last()">
				<xsl:value-of select="$charDelim"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$charAtEnd"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="addPDFUAmeta">
		<xsl:variable name="lang">
			<xsl:call-template name="getLang"/>
		</xsl:variable>
		<pdf:catalog>
			<pdf:dictionary type="normal" key="ViewerPreferences">
				<pdf:boolean key="DisplayDocTitle">true</pdf:boolean>
			</pdf:dictionary>
		</pdf:catalog>
		<x:xmpmeta xmlns:x="adobe:ns:meta/">
			<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
				<rdf:Description xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:pdf="http://ns.adobe.com/pdf/1.3/" rdf:about="">
					<!-- Dublin Core properties go here -->
					<dc:title>
						<xsl:variable name="title">
							<xsl:for-each select="(//*[contains(local-name(), '-standard')])[1]/ns:bibdata">
								<xsl:value-of select="ns:title[@language = $lang and @type = 'main']"/>
							</xsl:for-each>
						</xsl:variable>
						<xsl:choose>
							<xsl:when test="normalize-space($title) != ''">
								<xsl:value-of select="$title"/>
							</xsl:when>
							<xsl:otherwise>
								<xsl:text> </xsl:text>
							</xsl:otherwise>
						</xsl:choose>
					</dc:title>
					<dc:creator>
						<xsl:for-each select="(//*[contains(local-name(), '-standard')])[1]/ns:bibdata">
							<xsl:for-each select="ns:contributor[ns:role/@type='author']">
								<xsl:value-of select="ns:organization/ns:name"/>
								<xsl:if test="position() != last()">; </xsl:if>
							</xsl:for-each>
						</xsl:for-each>
					</dc:creator>
					<dc:description>
						<xsl:variable name="abstract">
							<xsl:copy-of select="//*[contains(local-name(), '-standard')]/ns:preface/ns:abstract//text()"/>
						</xsl:variable>
						<xsl:value-of select="normalize-space($abstract)"/>
					</dc:description>
					<pdf:Keywords>
						<xsl:call-template name="insertKeywords"/>
					</pdf:Keywords>
				</rdf:Description>
				<rdf:Description xmlns:xmp="http://ns.adobe.com/xap/1.0/" rdf:about="">
					<!-- XMP properties go here -->
					<xmp:CreatorTool/>
				</rdf:Description>
			</rdf:RDF>
		</x:xmpmeta>
	</xsl:template>

	<xsl:template name="getId">
		<xsl:choose>
			<xsl:when test="../@id">
				<xsl:value-of select="../@id"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="concat(generate-id(..), '_', text())"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="getLevel">
		<xsl:param name="depth"/>
		<xsl:choose>
			<xsl:when test="normalize-space(@depth) != ''">
				<xsl:value-of select="@depth"/>
			</xsl:when>
			<xsl:when test="normalize-space($depth) != ''">
				<xsl:value-of select="$depth"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="level_total" select="count(ancestor::*)"/>
				<xsl:variable name="level">
					<xsl:choose>
						<xsl:when test="parent::ns:preface">
							<xsl:value-of select="$level_total - 1"/>
						</xsl:when>
						<xsl:when test="ancestor::ns:preface and not(ancestor::ns:foreword) and not(ancestor::ns:introduction)">
							<!-- for preface/clause -->
							<xsl:value-of select="$level_total - 1"/>
						</xsl:when>
						<xsl:when test="ancestor::ns:preface">
							<xsl:value-of select="$level_total - 2"/>
						</xsl:when>
						
						<xsl:when test="ancestor::ns:sections">
							<xsl:value-of select="$level_total - 1"/>
						</xsl:when>
						<xsl:when test="ancestor::ns:bibliography">
							<xsl:value-of select="$level_total - 1"/>
						</xsl:when>
						<xsl:when test="parent::ns:annex">
							<xsl:value-of select="$level_total - 1"/>
						</xsl:when>
						<xsl:when test="ancestor::ns:annex">
							<xsl:value-of select="$level_total"/>
						</xsl:when>
						<xsl:when test="local-name() = 'annex'">1</xsl:when>
						<xsl:when test="local-name(ancestor::*[1]) = 'annex'">1</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="$level_total - 1"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>
				<xsl:value-of select="$level"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="split">
		<xsl:param name="pText" select="."/>
		<xsl:param name="sep" select="','"/>
		<xsl:param name="normalize-space" select="'true'"/>
		<xsl:if test="string-length($pText) &gt;0">
			<item>
				<xsl:choose>
					<xsl:when test="$normalize-space = 'true'">
						<xsl:value-of select="normalize-space(substring-before(concat($pText, $sep), $sep))"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="substring-before(concat($pText, $sep), $sep)"/>
					</xsl:otherwise>
				</xsl:choose>
			</item>
			<xsl:call-template name="split">
				<xsl:with-param name="pText" select="substring-after($pText, $sep)"/>
				<xsl:with-param name="sep" select="$sep"/>
				<xsl:with-param name="normalize-space" select="$normalize-space"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

	<xsl:template name="getDocumentId">
		<xsl:call-template name="getLang"/>
		<xsl:value-of select="//ns:p[1]/@id"/>
	</xsl:template>

	
	<xsl:template name="getLanguage">
		<xsl:param name="lang"/>
		<xsl:variable name="language" select="java:toLowerCase(java:java.lang.String.new($lang))"/>
		<xsl:choose>
			<xsl:when test="$language = 'en'">English</xsl:when>
			<xsl:when test="$language = 'fr'">French</xsl:when>
			<xsl:when test="$language = 'de'">Deutsch</xsl:when>
			<xsl:when test="$language = 'cn'">Chinese</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="$language"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="setId">
		<xsl:attribute name="id">
			<xsl:choose>
				<xsl:when test="@id">
					<xsl:value-of select="@id"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="generate-id()"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template>

	<xsl:template name="add-letter-spacing">
		<xsl:param name="text"/>
		<xsl:param name="letter-spacing" select="'0.15'"/>
		<xsl:if test="string-length($text) &gt; 0">
			<xsl:variable name="char" select="substring($text, 1, 1)"/>
			<fo:inline padding-right="{$letter-spacing}mm">
				<xsl:if test="$char = '®'">
					<xsl:attribute name="font-size">58%</xsl:attribute>
					<xsl:attribute name="baseline-shift">30%</xsl:attribute>
				</xsl:if>
				<xsl:value-of select="$char"/>
			</fo:inline>
			<xsl:call-template name="add-letter-spacing">
				<xsl:with-param name="text" select="substring($text, 2)"/>
				<xsl:with-param name="letter-spacing" select="$letter-spacing"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

	<xsl:template name="repeat">
		<xsl:param name="char" select="'*'"/>
		<xsl:param name="count"/>
		<xsl:if test="$count &gt; 0">
			<xsl:value-of select="$char"/>
			<xsl:call-template name="repeat">
				<xsl:with-param name="char" select="$char"/>
				<xsl:with-param name="count" select="$count - 1"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

	<xsl:template name="getLocalizedString">
		<xsl:param name="key"/>
		<xsl:variable name="curr_lang">
			<xsl:call-template name="getLang"/>
		</xsl:variable>
		<xsl:variable name="data_value" select="normalize-space(xalan:nodeset($bibdata)//ns:localized-string[@key = $key and @language = $curr_lang])"/>
		<xsl:choose>
			<xsl:when test="$data_value != ''">
				<xsl:value-of select="$data_value"/>
			</xsl:when>
			<xsl:when test="/*/ns:localized-strings/ns:localized-string[@key = $key and @language = $curr_lang]">
				<xsl:value-of select="/*/ns:localized-strings/ns:localized-string[@key = $key and @language = $curr_lang]"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:variable name="key_">
					<xsl:call-template name="capitalize">
						<xsl:with-param name="str" select="translate($key, '_', ' ')"/>
					</xsl:call-template>
				</xsl:variable>
				<xsl:value-of select="$key_"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="setTrackChangesStyles">
		<xsl:param name="isAdded"/>
		<xsl:param name="isDeleted"/>
		<xsl:choose>
			<xsl:when test="local-name() = 'math'">
				<xsl:if test="$isAdded = 'true'">
					<xsl:attribute name="background-color">
						<xsl:value-of select="$color-added-text"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:if test="$isDeleted = 'true'">
					<xsl:attribute name="background-color">
						<xsl:value-of select="$color-deleted-text"/>
					</xsl:attribute>
				</xsl:if>
			</xsl:when>
			<xsl:otherwise>
				<xsl:if test="$isAdded = 'true'">
					<xsl:attribute name="border">
						<xsl:value-of select="$border-block-added"/>
					</xsl:attribute>
					<xsl:attribute name="padding">2mm</xsl:attribute>
				</xsl:if>
				<xsl:if test="$isDeleted = 'true'">
					<xsl:attribute name="border">
						<xsl:value-of select="$border-block-deleted"/>
					</xsl:attribute>
					<xsl:if test="local-name() = 'table'">
						<xsl:attribute name="background-color">rgb(255, 185, 185)</xsl:attribute>
					</xsl:if>
					<!-- <xsl:attribute name="color"><xsl:value-of select="$color-deleted-text"/></xsl:attribute> -->
					<xsl:attribute name="padding">2mm</xsl:attribute>
				</xsl:if>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<xsl:variable name="LRM" select="'‎'"/>
	<xsl:variable name="RLM" select="'‏'"/>
	<xsl:template name="setWritingMode">
		<xsl:if test="$lang = 'ar'">
			<xsl:attribute name="writing-mode">rl-tb</xsl:attribute>
		</xsl:if>
	</xsl:template>

	<xsl:template name="setAlignment">
		<xsl:param name="align" select="normalize-space(@align)"/>
		<xsl:choose>
			<xsl:when test="$lang = 'ar' and $align = 'left'">start</xsl:when>
			<xsl:when test="$lang = 'ar' and $align = 'right'">end</xsl:when>
			<xsl:when test="$align != ''">
				<xsl:value-of select="$align"/>
			</xsl:when>
		</xsl:choose>
	</xsl:template>

	<xsl:template name="setTextAlignment">
		<xsl:param name="default">left</xsl:param>
		<xsl:attribute name="text-align">
			<xsl:choose>
				<xsl:when test="@align">
					<xsl:value-of select="@align"/>
				</xsl:when>
				<xsl:when test="ancestor::ns:td/@align">
					<xsl:value-of select="ancestor::ns:td/@align"/>
				</xsl:when>
				<xsl:when test="ancestor::ns:th/@align">
					<xsl:value-of select="ancestor::ns:th/@align"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$default"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:attribute>
	</xsl:template>

	<xsl:template name="number-to-words">
		<xsl:param name="number"/>
		<xsl:param name="first"/>
		<xsl:if test="$number != ''">
			<xsl:variable name="words">
				<words>
					<word cardinal="1">One-</word>
					<word ordinal="1">First </word>
					<word cardinal="2">Two-</word>
					<word ordinal="2">Second </word>
					<word cardinal="3">Three-</word>
					<word ordinal="3">Third </word>
					<word cardinal="4">Four-</word>
					<word ordinal="4">Fourth </word>
					<word cardinal="5">Five-</word>
					<word ordinal="5">Fifth </word>
					<word cardinal="6">Six-</word>
					<word ordinal="6">Sixth </word>
					<word cardinal="7">Seven-</word>
					<word ordinal="7">Seventh </word>
					<word cardinal="8">Eight-</word>
					<word ordinal="8">Eighth </word>
					<word cardinal="9">Nine-</word>
					<word ordinal="9">Ninth </word>
					<word ordinal="10">Tenth </word>
					<word ordinal="11">Eleventh </word>
					<word ordinal="12">Twelfth </word>
					<word ordinal="13">Thirteenth </word>
					<word ordinal="14">Fourteenth </word>
					<word ordinal="15">Fifteenth </word>
					<word ordinal="16">Sixteenth </word>
					<word ordinal="17">Seventeenth </word>
					<word ordinal="18">Eighteenth </word>
					<word ordinal="19">Nineteenth </word>
					<word cardinal="20">Twenty-</word>
					<word ordinal="20">Twentieth </word>
					<word cardinal="30">Thirty-</word>
					<word ordinal="30">Thirtieth </word>
					<word cardinal="40">Forty-</word>
					<word ordinal="40">Fortieth </word>
					<word cardinal="50">Fifty-</word>
					<word ordinal="50">Fiftieth </word>
					<word cardinal="60">Sixty-</word>
					<word ordinal="60">Sixtieth </word>
					<word cardinal="70">Seventy-</word>
					<word ordinal="70">Seventieth </word>
					<word cardinal="80">Eighty-</word>
					<word ordinal="80">Eightieth </word>
					<word cardinal="90">Ninety-</word>
					<word ordinal="90">Ninetieth </word>
					<word cardinal="100">Hundred-</word>
					<word ordinal="100">Hundredth </word>
				</words>
			</xsl:variable>
			<xsl:variable name="ordinal" select="xalan:nodeset($words)//word[@ordinal = $number]/text()"/>
			<xsl:variable name="value">
				<xsl:choose>
					<xsl:when test="$ordinal != ''">
						<xsl:value-of select="$ordinal"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:choose>
							<xsl:when test="$number &lt; 100">
								<xsl:variable name="decade" select="concat(substring($number,1,1), '0')"/>
								<xsl:variable name="digit" select="substring($number,2)"/>
								<xsl:value-of select="xalan:nodeset($words)//word[@cardinal = $decade]/text()"/>
								<xsl:value-of select="xalan:nodeset($words)//word[@ordinal = $digit]/text()"/>
							</xsl:when>
							<xsl:otherwise>
								<!-- more 100 -->
								<xsl:variable name="hundred" select="substring($number,1,1)"/>
								<xsl:variable name="digits" select="number(substring($number,2))"/>
								<xsl:value-of select="xalan:nodeset($words)//word[@cardinal = $hundred]/text()"/>
								<xsl:value-of select="xalan:nodeset($words)//word[@cardinal = '100']/text()"/>
								<xsl:call-template name="number-to-words">
									<xsl:with-param name="number" select="$digits"/>
								</xsl:call-template>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			<xsl:choose>
				<xsl:when test="$first = 'true'">
					<xsl:variable name="value_lc" select="java:toLowerCase(java:java.lang.String.new($value))"/>
					<xsl:call-template name="capitalize">
						<xsl:with-param name="str" select="$value_lc"/>
					</xsl:call-template>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$value"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:if>
	</xsl:template>

	<xsl:template name="processPersonalAuthor">
		<xsl:choose>
			<xsl:when test="ns:name/ns:completename">
				<author>
					<xsl:apply-templates select="ns:name/ns:completename"/>
				</author>
			</xsl:when>
			<xsl:when test="ns:name/ns:surname and ns:name/ns:initial">
				<author>
					<xsl:apply-templates select="ns:name/ns:surname"/>
					<xsl:text> </xsl:text>
					<xsl:apply-templates select="ns:name/ns:initial" mode="strip"/>
				</author>
			</xsl:when>
			<xsl:when test="ns:name/ns:surname and ns:name/ns:forename">
				<author>
					<xsl:apply-templates select="ns:name/ns:surname"/>
					<xsl:text> </xsl:text>
					<xsl:apply-templates select="ns:name/ns:forename" mode="strip"/>
				</author>
			</xsl:when>
			<xsl:otherwise>
				<xsl:apply-templates/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- ======================= -->
	<!-- END Functions (named templates) -->
	<!-- ======================= -->

</xsl:stylesheet>