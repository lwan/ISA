package ch.unil.cbg.ExpressionView.view {
	
	import __AS3__.vec.Vector;
	
	import ch.unil.cbg.ExpressionView.events.*;
	import ch.unil.cbg.ExpressionView.model.*;
	import ch.unil.cbg.ExpressionView.view.components.*;
	
	import flash.events.MouseEvent;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	
	import flexlib.containers.SuperTabNavigator;
	
	import mx.containers.Canvas;
	import mx.containers.Panel;
	import mx.containers.TabNavigator;
	import mx.controls.Text;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.events.IndexChangedEvent;
	import mx.events.ListEvent;
	
	import nl.wv.extenders.panel.SuperPanel;
	
	import org.alivepdf.colors.RGBColor;
	import org.alivepdf.fonts.FontFamily;
	import org.alivepdf.fonts.Style;
	import org.alivepdf.layout.Orientation;
	import org.alivepdf.layout.Size;
	import org.alivepdf.layout.Unit;
	import org.alivepdf.pdf.PDF;
	import org.alivepdf.saving.Method;

	public class MainCanvas extends Canvas {
		
		private var useDefaultPositions:Boolean;
		
		private var rawged:GeneExpressionData;
		private var ged:GeneExpressionData;
		
		private var selectedMode:int;
		
		private var lastHighlightedModules:Array;
		
		private var gePanel:SuperPanel;
		private var modulesNavigator:SuperTabNavigator;
		private var openTabs:Vector.<ZoomPanCanvas>;
		private var mapOpenTabs:Vector.<int>;
		
		private var infoPanel:SuperPanel;
		private var infoContent:Text;
		
		private var modulesPanel:SuperPanel;
		private var modulesSearchableDataGrid:SearchableDataGrid;
		
		private var genesPanel:SuperPanel;
		private var genesSearchableDataGrid:SearchableDataGrid;		
		private var samplesPanel:SuperPanel;
		private var samplesSearchableDataGrid:SearchableDataGrid;

		private var currentalpha:Number;
				
		public function MainCanvas() {
			super();

			ged = new GeneExpressionData();
			lastHighlightedModules = new Array();
			useDefaultPositions = true;
		}
		
		override protected function createChildren(): void {
			
			super.createChildren();
						
			if ( !gePanel ) {
				gePanel = new SuperPanel();
				addChild(gePanel);
				
				if ( !modulesNavigator ) {
					modulesNavigator = new SuperTabNavigator();
					modulesNavigator.addEventListener(IndexChangedEvent.CHANGE, tabChangeHandler);
					gePanel.addChild(modulesNavigator);
					
					openTabs = new Vector.<ZoomPanCanvas>;
					mapOpenTabs = new Vector.<int>;

				}
			}
			
			if ( !infoPanel ) {
				infoPanel = new SuperPanel();
				infoPanel.showControls = true;
				infoPanel.enableResize = true;
				infoPanel.setStyle("backgroundColor", "white");
				infoPanel.alpha = 0.8;
				infoPanel.title = "Info";
				addChild(infoPanel);
				
				if ( !infoContent ) {
					infoContent = new Text();
					infoPanel.addChild(infoContent);
				}
				
			}
		
			if ( !modulesPanel ) {
				modulesPanel = new SuperPanel();
				modulesPanel.title = "Modules";
				addChild(modulesPanel);
												
				if ( !modulesSearchableDataGrid ) {
					modulesSearchableDataGrid = new SearchableDataGrid();
					modulesSearchableDataGrid.addEventListener(SearchableDataGridSelectionEvent.ITEM_CLICK, clickModulesHandler);
					modulesSearchableDataGrid.addEventListener(SearchableDataGridSelectionEvent.ITEM_DOUBLE_CLICK, doubleClickModulesHandler);
					modulesPanel.addChild(modulesSearchableDataGrid);
				}
							
			}

			if ( !genesPanel ) {
				genesPanel = new SuperPanel();
				genesPanel.title = "Genes";
				addChild(genesPanel);
												
				if ( !genesSearchableDataGrid ) {
					genesSearchableDataGrid = new SearchableDataGrid();
					genesSearchableDataGrid.addEventListener(ListEvent.ITEM_CLICK, clickGenesHandler);
					genesSearchableDataGrid.addEventListener(ListEvent.ITEM_DOUBLE_CLICK, doubleClickGenesHandler);
					genesPanel.addChild(genesSearchableDataGrid);
				}			
			}
			
			if ( !samplesPanel ) {
				samplesPanel = new SuperPanel();
				samplesPanel.title = "Samples";
				addChild(samplesPanel);
												
				if ( !samplesSearchableDataGrid ) {
					samplesSearchableDataGrid = new SearchableDataGrid();
					samplesSearchableDataGrid.addEventListener(ListEvent.ITEM_CLICK, clickSamplesHandler);
					samplesSearchableDataGrid.addEventListener(ListEvent.ITEM_DOUBLE_CLICK, doubleClickSamplesHandler);
					samplesPanel.addChild(samplesSearchableDataGrid);
				}			
			}

			useDefaultPositions = true;
			
			parentApplication.addEventListener(SetDefaultPositionsEvent.SETDEFAULTPOSITIONSEVENT, setDefaultPositionsHandler);
			parentApplication.addEventListener(UpdateGEDataEvent.UPDATEGEDATAEVENT, updateGEDataHandler);
			parentApplication.addEventListener(ModeChangeEvent.MODECHANGEEVENT, modeChangeHandler);
			parentApplication.addEventListener(SetPanelVisibilityEvent.SETPANELVISIBILITYEVENT, setPanelVisibilityHandler);
			parentApplication.addEventListener(BroadcastInspectPositionEvent.BROADCASTINSPECTPOSITIONEVENT, broadcastInspectPositionHandler);
			parentApplication.addEventListener(PDFExportEvent.PDFEXPORTEVENT, pdfExportHandler);
			parentApplication.addEventListener(AlphaSliderChangeEvent.ALPHASLIDERCHANGEEVENT, alphaSliderChangeHandler);	
			parentApplication.addEventListener(ResizeBrowserEvent.RESIZEBROWSEREVENT, resizeBrowserHandler);
		}
		
		
		private function resizeBrowserHandler(event:ResizeBrowserEvent): void {
			
			var scalex:Number = event.scaleX;
			var scaley:Number = event.scaleY;
			
			if ( isFinite(scalex) && isFinite(scaley) ) {
				gePanel.x *= scalex;
				infoPanel.x *= scalex;
				modulesPanel.x *= scalex;
				genesPanel.x *= scalex;			
				samplesPanel.x *= scalex;
				
				gePanel.width *= scalex;
				infoPanel.width *= scalex;
				modulesPanel.width *= scalex;
				genesPanel.width *= scalex;			
				samplesPanel.width *= scalex;

				gePanel.y *= scaley;
				infoPanel.y *= scaley;
				modulesPanel.y *= scaley;
				genesPanel.y *= scaley;			
				samplesPanel.y *= scaley;

				gePanel.height *= scaley;
				infoPanel.height *= scaley;
				modulesPanel.height *= scaley;
				genesPanel.height *= scaley;			
				samplesPanel.height *= scaley;
			}
			
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			
			super.updateDisplayList(unscaledWidth, unscaledHeight);

			modulesSearchableDataGrid.percentWidth = 100;
			modulesSearchableDataGrid.percentHeight = 100;
			genesSearchableDataGrid.percentWidth = 100;
			genesSearchableDataGrid.percentHeight = 100;
			samplesSearchableDataGrid.percentWidth = 100;
			samplesSearchableDataGrid.percentHeight = 100;

			modulesNavigator.percentWidth = 100;
			modulesNavigator.percentHeight = 100;
				
			for ( var module:int = 0; module < openTabs.length; ++module ) {
				openTabs[module].percentWidth = 100;
				openTabs[module].percentHeight = 100;
			}
			
			if ( useDefaultPositions ) {

				var width:Number = stage.stageWidth * 1/4;
				var x:Number = 3 * width;
				var y:Number = (stage.stageHeight - 70) / 4;

				gePanel.x = 0;
				gePanel.y = 0;
				gePanel.percentWidth = 75;
				gePanel.percentHeight = 100;
				
				infoPanel.x = x;
				infoPanel.y = 0;
				infoPanel.width = width;
				infoPanel.height = y;
				
				modulesPanel.x = x;
				modulesPanel.y = y;
				modulesPanel.width = width;
				modulesPanel.height = y;
							
				genesPanel.x = x;
				genesPanel.y = 2*y;
				genesPanel.width = width;
				genesPanel.height = y;
				
				samplesPanel.x = x;
				samplesPanel.y = 3*y;
				samplesPanel.width = width;
				samplesPanel.height = y;
				
			}
			useDefaultPositions = false;
			
		}

		private function modeChangeHandler(event:ModeChangeEvent): void {
			if ( event.mode != selectedMode ) {
				lastHighlightedModules = new Array();
			}
			selectedMode = event.mode;
		}
		
		private function tabChangeHandler(event:IndexChangedEvent): void {
			openTabs[event.oldIndex].removeListener();
			openTabs[event.newIndex].addListener();
			dispatchEvent(new ModeChangeEvent(selectedMode));
		}
		
		private function clickModulesHandler(event:SearchableDataGridSelectionEvent): void {
			var module:int = mapOpenTabs[modulesNavigator.selectedIndex];
			var highlightedModules:Array = [];
			for ( var i:int = 0; i < event.selection.length; ++i ) {
				var selectedModule:int = event.selection[i];
				highlightedModules = highlightedModules.concat(ged.getModule(module).ModulesRectangles[selectedModule])
			}
			dispatchEvent(new UpdateHighlightedModulesEvent(highlightedModules));
		}
		
		private function doubleClickModulesHandler(event:SearchableDataGridSelectionEvent): void {
			
			for ( var i:int = 0; i < event.selection.length; ++i ) {
				var selectedModule:int = event.selection[i];
				var selectedTab:int = mapOpenTabs.indexOf(selectedModule);
				if ( selectedTab == -1 ) {
					var gem:GeneExpressionModule = ged.getModule(selectedModule);
					selectedTab = openTabs.push(new ZoomPanCanvas()) - 1;
					modulesNavigator.addChild(openTabs[selectedTab]);
					openTabs[selectedTab].label = "Module " + selectedModule.toString();
					var largestRectangles:Array = [];
					openTabs[selectedTab].dataProvider = new Array(gem.GEImage, gem.ModulesImage, largestRectangles);
					genesSearchableDataGrid.dataProvider = gem.Genes;
					samplesSearchableDataGrid.dataProvider = gem.Samples;	
					mapOpenTabs.push(selectedModule);
				}
				var lastSelectedTab:int = modulesNavigator.selectedIndex; 
				if ( lastSelectedTab != selectedTab ) { 
					openTabs[lastSelectedTab].removeListener();
					openTabs[selectedTab].addListener();
					modulesNavigator.selectedIndex = selectedTab;
				}
				
			}			
		}

		private function clickGenesHandler(event:ListEvent): void {
		}
		private function doubleClickGenesHandler(event:ListEvent): void {
		}

		private function clickSamplesHandler(event:ListEvent): void {
		}
		private function doubleClickSamplesHandler(event:ListEvent): void {
		}

		private function broadcastInspectPositionHandler(event:BroadcastInspectPositionEvent): void {
			var gene:int = event.gene;
			var sample:int = event.sample;
			
			infoContent.text = "";
			var module:int = mapOpenTabs[modulesNavigator.selectedIndex]
			// Array returned is Array(geneDescription, sampleDescription, modules, data, modulesRectangles);
			var infoArray:Array = ged.getInfo(module, gene, sample);
			if ( infoArray != null ) {
				var modules:Array = infoArray[2];
				// update infoPanel
				var infoString:String = "";
				if ( infoArray.length != 0 ) {
					infoString = infoString + "Gene: " + infoArray[0].genetag1;
					infoString = infoString + "\nSample: " + infoArray[1].sampletag1;
					infoString = infoString + "\nModules: " + infoArray[2];
					infoString = infoString + "\nData: " + infoArray[3];
				}
				infoContent.text = infoString;
	
				// highlight module
				if ( lastHighlightedModules != modules ) {
					var highlightedModules:Array = [];
					for ( var modulep:int = 0; modulep < modules.length; ++modulep ) {
						if ( modules[modulep] != module ) {
							highlightedModules = highlightedModules.concat(ged.getModule(module).ModulesRectangles[modules[modulep]]);
						}
					}
					dispatchEvent(new UpdateHighlightedModulesEvent(highlightedModules));
					lastHighlightedModules = modules;
				}
			
			} else {
				infoContent.text = "";
				dispatchEvent(new UpdateHighlightedModulesEvent([]));
			}
		}
		
		private function setDefaultPositionsHandler(event:SetDefaultPositionsEvent): void {
			useDefaultPositions = true;
			invalidateDisplayList();
		}
		
		private function setPanelVisibilityHandler(event:SetPanelVisibilityEvent): void {
			var panel:String = event.panel;
			var visible:Boolean = event.visible;
			
			switch (panel) {
				case "info":
					infoPanel.visible = visible;
					break;
				case "modules":
					modulesPanel.visible = visible;
					break;
				case "genes":
					genesPanel.visible = visible;
					break;
				case "samples":
					samplesPanel.visible = visible;
					break;
			}			
		}
		
		private function updateGEDataHandler(event:UpdateGEDataEvent): void {
			rawged = event.data[0]
			ged = event.data[1];
			var gem:GeneExpressionModule = ged.getModule(0);

			modulesSearchableDataGrid.dataProvider = ged.Modules;
			genesSearchableDataGrid.dataProvider = gem.Genes;
			samplesSearchableDataGrid.dataProvider = gem.Samples;
			var temp:Array = [];
			for ( var i:int = 1; i < ged.shortLabelsGene.length; i++ ) {
				var column:DataGridColumn = new DataGridColumn();
				column.dataField = "genetag" + i;
				column.headerText = ged.shortLabelsGene[i];
				temp.push(column)
			}
			genesSearchableDataGrid.columns = temp;
			temp = [];
			for ( i = 1; i < ged.shortLabelsSample.length; i++ ) {
				column = new DataGridColumn();
				column.dataField = "sampletag" + i;
				column.headerText = ged.shortLabelsSample[i];
				temp.push(column)
			}
			samplesSearchableDataGrid.columns = temp;
			temp = [];
			for ( i = 1; i < ged.shortLabelsModule.length; i++ ) {
				column = new DataGridColumn();
				column.dataField = "moduletag" + i;
				column.headerText = ged.shortLabelsModule[i];
				temp.push(column)
			}
			modulesSearchableDataGrid.columns = temp;

			modulesNavigator.removeAllChildren();
			
			openTabs = new Vector.<ZoomPanCanvas>;					
			var selectedTab:int = openTabs.push(new ZoomPanCanvas()) - 1;
			modulesNavigator.addChild(openTabs[selectedTab]);

			var largestRectangles:Array = [];
			for ( i = 1; i <= ged.nModules; ++i ) {
				largestRectangles.push(gem.ModulesRectangles[i][gem.ModulesOutlines[i-1]]);
			}
			openTabs[selectedTab].label = "Global";
			openTabs[selectedTab].colors = ged.ModulesColors;
			openTabs[selectedTab].dataProvider = new Array(gem.GEImage, gem.ModulesImage, largestRectangles);
			openTabs[selectedTab].addListener();
			openTabs[selectedTab].addEventListener(MouseEvent.ROLL_OUT, rollOutHandler);

			mapOpenTabs = new Vector.<int>;
			mapOpenTabs.push(0);				
		}
		
		private function rollOutHandler(event:MouseEvent): void {
			dispatchEvent(new UpdateHighlightedModulesEvent([]))
		}
		
		private function pdfExportHandler(event:PDFExportEvent): void {
				
			var myPDF:PDF;
			myPDF = new PDF(Orientation.PORTRAIT, Unit.MM, Size.A4);
			myPDF.addPage();
			myPDF.textStyle(new RGBColor(10));
			myPDF.setFont(FontFamily.HELVETICA, Style.BOLD);
			myPDF.setFontSize(14);
			myPDF.addText("ExpressionView Export", 10, 10);
			myPDF.addImage(openTabs[modulesNavigator.selectedIndex].currentgeimage,10,20,190,0);
			myPDF.addImage(openTabs[modulesNavigator.selectedIndex].currentmodulesimage,10,20,190,0,null,100,currentalpha);

			var bytes:ByteArray = myPDF.save(Method.LOCAL);
			var file:FileReference = new FileReference();
			file.save(bytes);
	
		}
		
		private function alphaSliderChangeHandler(event:AlphaSliderChangeEvent): void {
			currentalpha = event.alpha;
		}
		
	}
}