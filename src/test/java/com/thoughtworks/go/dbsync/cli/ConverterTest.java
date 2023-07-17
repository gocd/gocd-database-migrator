/*
 * Copyright 2020 ThoughtWorks, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.thoughtworks.go.dbsync.cli;

import liquibase.util.StringUtils;
import org.junit.jupiter.api.Test;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.BiConsumer;

class ConverterTest {

    @Test
    void name() throws Exception {
        DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
        DocumentBuilder documentBuilder = dbf.newDocumentBuilder();
        Document sourceDocument = documentBuilder.parse(new File("src/test/resources/full.xml"));
        Element sourceDocumentElement = sourceDocument.getDocumentElement();

        rewriteStuffInInputXML(sourceDocumentElement);

        copySchemaMigrationStatements(dbf, sourceDocumentElement);
        copyConstraintsAndIndexMigrationStatements(dbf, sourceDocumentElement);
        copyCreateViewMigrationStatements(dbf, sourceDocumentElement);

        writeDocumentToFile("left-over.xml", sourceDocument);
    }

    private void copyCreateViewMigrationStatements(DocumentBuilderFactory dbf, Element sourceDocumentElement) throws ParserConfigurationException, TransformerException {
        Document viewDocument = dbf.newDocumentBuilder().newDocument();
        copyChangesetsContaining(sourceDocumentElement, viewDocument, "createView");
        writeDocumentToFile("create-view.xml", viewDocument);
    }

    private void copyConstraintsAndIndexMigrationStatements(DocumentBuilderFactory dbf, Element sourceDocumentElement) throws ParserConfigurationException, TransformerException {
        Document indexDocument = dbf.newDocumentBuilder().newDocument();
        copyChangesetsContaining(sourceDocumentElement, indexDocument, "addUniqueConstraint");
        copyChangesetsContaining(sourceDocumentElement, indexDocument, "createIndex");
        copyChangesetsContaining(sourceDocumentElement, indexDocument, "constraints");
        copyChangesetsContaining(sourceDocumentElement, indexDocument, "addForeignKeyConstraint");
        writeDocumentToFile("create-index.xml", indexDocument);
    }

    private void copySchemaMigrationStatements(DocumentBuilderFactory dbf, Element sourceDocumentElement) throws ParserConfigurationException, TransformerException {
        Document schemaDocument = dbf.newDocumentBuilder().newDocument();
        copyChangesetsContaining(sourceDocumentElement, schemaDocument, "createTable");
        writeDocumentToFile("create-schema.xml", schemaDocument);
    }

    private void rewriteStuffInInputXML(Element sourceDocumentElement) throws Exception {
        dropChangelogTable(sourceDocumentElement);
        rewriteChangeSetIDs(sourceDocumentElement);
        rewriteAutoGeneratedConstraintNames(sourceDocumentElement);
        rewriteChangeSetColumnTags(sourceDocumentElement, properties("h2"));
    }

    private void rewriteAutoGeneratedConstraintNames(Element sourceDocumentElement) {
        rewriteAutoNamedConstraintsOnNodesWithTag(sourceDocumentElement, "addUniqueConstraint", "constraintName", (constraintNode, attributeValue) -> {
            if (attributeValue.toUpperCase().startsWith("CONSTRAINT_")) {
                constraintNode.removeAttribute("constraintName");
            }
        });
        rewriteAutoNamedConstraintsOnNodesWithTag(sourceDocumentElement, "createIndex", "indexName", (constraintNode, attributeValue) -> {
            if (attributeValue.toUpperCase().contains("_INDEX_")) {
                constraintNode.setAttribute("indexName", attributeValue.replaceAll("_INDEX_(.{1,3})", ""));
                constraintNode.setAttribute("indexName", attributeValue.replaceAll("_index_(.{1,3})", ""));
            }
        });
        rewriteAutoNamedConstraintsOnNodesWithTag(sourceDocumentElement, "constraints", "primaryKeyName", (constraintNode, attributeValue) -> {
            if (attributeValue.toUpperCase().startsWith("CONSTRAINT_")) {
                constraintNode.removeAttribute("primaryKeyName");
            }
        });
        rewriteAutoNamedConstraintsOnNodesWithTag(sourceDocumentElement, "addForeignKeyConstraint", "constraintName", (constraintNode, attributeValue) -> {
            if (attributeValue.toUpperCase().startsWith("CONSTRAINT_")) {
                constraintNode.removeAttribute("constraintName");
            }
        });
    }

    private void writeDocumentToFile(String fileName, Document schemaDocument) throws TransformerException {
        //for output to file, console
        TransformerFactory transformerFactory = TransformerFactory.newInstance();
        Transformer transformer = transformerFactory.newTransformer();
        //for pretty print
        transformer.setOutputProperty(OutputKeys.INDENT, "yes");
        transformer.setOutputProperty("{http://xml.apache.org/xslt}indent-amount", "4");
        DOMSource schemaSource = new DOMSource(schemaDocument);
        File outputFile = new File("generated", fileName);
        //noinspection ResultOfMethodCallIgnored
        outputFile.getParentFile().mkdirs();
        transformer.transform(schemaSource, new StreamResult(outputFile));
    }

    private void dropChangelogTable(Element sourceDocumentElement) {
        NodeList createTable = sourceDocumentElement.getElementsByTagName("createTable");
        for (int i = 0; i < createTable.getLength(); i++) {
            Element item = (Element) createTable.item(i);
            if (item.hasAttribute("tableName") && item.getAttribute("tableName").equalsIgnoreCase("CHANGELOG")) {
                item.getParentNode().removeChild(item);
                return;
            }
        }
    }

    private void copyChangesetsContaining(Element sourceDocumentElement, Document targetDocument, String nodeNameToCopy) {
        NodeList createTableNodes = sourceDocumentElement.getElementsByTagName(nodeNameToCopy);

        if (targetDocument.getDocumentElement() == null) {
            Node rootNode = targetDocument.importNode(sourceDocumentElement.cloneNode(false), false);
            targetDocument.appendChild(rootNode);
        }

        Node rootNode = targetDocument.getDocumentElement();

        List<Node> changesetNodes = new ArrayList<>();
        for (int i = 0; i < createTableNodes.getLength(); i++) {
            Node createTableNode = createTableNodes.item(i);
            Node changesetNode = createTableNode.getParentNode();
            changesetNodes.add(changesetNode);
        }

        for (Node changesetNode : changesetNodes) {
            Node node = targetDocument.importNode(changesetNode, true);
            rootNode.appendChild(node);
            sourceDocumentElement.removeChild(changesetNode);
        }
    }

    private void rewriteAutoNamedConstraintsOnNodesWithTag(Element documentElement, String tagName, String attributeName, BiConsumer<Element, String> filterFunction) {
        NodeList constraintNodes = documentElement.getElementsByTagName(tagName);

        for (int i = 0; i < constraintNodes.getLength(); i++) {
            Element constraintNode = (Element) constraintNodes.item(i);
            if (constraintNode.hasAttribute(attributeName)) {
                String attributeValue = constraintNode.getAttribute(attributeName);
                filterFunction.accept(constraintNode, attributeValue);
            }
        }
    }

    private void rewriteChangeSetColumnTags(Element documentElement, Map<String, String> columnTypeMappings) {
        NodeList columnNodes = documentElement.getElementsByTagName("column");
        for (int i = 0; i < columnNodes.getLength(); i++) {
            Element columnNode = (Element) columnNodes.item(i);
            if (columnNode.hasAttribute("type")) {
                String type = columnNode.getAttribute("type");
                String newType = columnTypeMappings.get(type);
                if (newType == null) {
                    throw new RuntimeException("Unknown node type " + type + " on column " + ((Element) columnNode.getParentNode()).getAttribute("tableName") + "." + columnNode.getAttribute("name"));
                }
                columnNode.setAttribute("type", "${" + newType + "}");
            }
        }
    }

    private void rewriteChangeSetIDs(Element documentElement) {
        NodeList changeSetNodes = documentElement.getElementsByTagName("changeSet");

        for (int i = 0; i < changeSetNodes.getLength(); i++) {
            Element changeSetNode = (Element) changeSetNodes.item(i);
            changeSetNode.setAttribute("id", String.valueOf(i + 1));
        }
    }

    Map<String, String> properties(String db) throws Exception {
        DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
        DocumentBuilder documentBuilder = dbf.newDocumentBuilder();
        Document document = documentBuilder.parse(getClass().getResourceAsStream("/liquibase.xml"));

        HashMap<String, String> result = new HashMap<>();

        NodeList properties = document.getDocumentElement().getElementsByTagName("property");
        for (int i = 0; i < properties.getLength(); i++) {
            Element property = (Element) properties.item(i);
            String dbms = property.getAttribute("dbms");
            if (!dbms.isBlank()) {
                List<String> dbs = StringUtils.splitAndTrim(dbms, ",");
                if (dbs.contains(db)) {
                    result.put(property.getAttribute("value"), property.getAttribute("name"));
                }
            }
        }
        return result;
    }
}
