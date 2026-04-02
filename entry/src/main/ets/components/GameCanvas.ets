import { UIContext, NodeController, FrameNode, RenderNode, DrawContext } from '@kit.ArkUI';
import { common2D, drawing } from '@kit.ArkGraphics2D';
import { basicNodeColor, Game, ItemType, node1Color, node2Color, NodeInfo, PathId } from '../core/Game'

export const canvasSize: number[] = [466, 466];

class Canvas extends RenderNode {
  level: number = 1;
  game = new Game(this.getLevelFileNameByLevel(this.level), canvasSize[0], canvasSize[1]);

  async loadLevel(level: number) {
    this.game = new Game(this.getLevelFileNameByLevel(level), canvasSize[0], canvasSize[1]);
    await this.game.create();
  }

  getLevelFileNameByLevel(level: number) {
    return `level${level}.json`;
  }

  drawNode(canvas: drawing.Canvas, pen: drawing.Pen, brush: drawing.Brush, nodeLoc: number[], nodeColor: common2D.Color,
    radius: number, thickness: number, isEmpty: boolean) {
    if (isEmpty) {
      pen.setColor(nodeColor);
      pen.setStrokeWidth(thickness);
      canvas.detachBrush();
      canvas.attachPen(pen);
      canvas.drawCircle(nodeLoc[0], nodeLoc[1], radius - thickness / 2);
    } else {
      brush.setColor(nodeColor);
      canvas.attachBrush(brush);
      canvas.detachPen();
      canvas.drawCircle(nodeLoc[0], nodeLoc[1], radius);
    }
  }

  async draw(context: DrawContext) {
    const canvas = context.canvas;
    if (canvas === null) {
      console.error('Canvas is null.');
      return;
    }

    const brush = new drawing.Brush();
    const pen = new drawing.Pen();
    if (brush === null || pen === null) {
      console.error('Brush or pen is null.');
      return;
    } else {

      // draw nodes
      for (let j = 0; j < this.game.map.nodes.length; j++) {
        for (let i = 0; i < this.game.map.nodes[j].length; i++) {
          const nodeLoc: number[] = this.game.getItemScreenLocation(i, j);
          const node: NodeInfo = this.game.getNodeInfo(i, j);

          if (node.radius === 0) {
            continue; // for empty ItemType
          }

          if (node.innerNodeRadius !== 0) { // if innerNodeRadius is not 0, it is a common node
            const commonNodePaths = this.game.getCommonNodePaths(i, j)
            const outerColor = commonNodePaths.outerPath === PathId.noPath ? basicNodeColor :
              commonNodePaths.outerPath === PathId.path1 ? node1Color : node2Color
            this.drawNode(canvas, pen, brush, nodeLoc, outerColor, node.radius, node.thickness,
              commonNodePaths.outerPath === PathId.noPath);
          } else {
            this.drawNode(canvas, pen, brush, nodeLoc, node.color, node.radius, node.thickness, node.isEmpty);
          }

        }
      }

      // draw paths
      const paths = [this.game.path1, this.game.path2];
      const pathColors = [node1Color, node2Color];
      let pathIndex = 0;
      for (const path of paths) {
        for (let i = 0; i < path.length - 1; i++) {
          const point1 = this.game.getItemScreenLocation(path[i][0], path[i][1]);
          const point2 = this.game.getItemScreenLocation(path[i + 1][0], path[i + 1][1]);

          pen.setColor(pathColors[pathIndex]);

          pen.setStrokeWidth(10);
          canvas.attachPen(pen);
          canvas.drawLine(point1[0], point1[1], point2[0], point2[1]);

        }
        pathIndex++;
      }

      // draw common node inner circles after path drawing
      for (let j = 0; j < this.game.map.nodes.length; j++) {
        for (let i = 0; i < this.game.map.nodes[j].length; i++) {
          if (this.game.map.nodes[j][i] !== ItemType.CommonNode) {
            continue;
          }

          const nodeLoc: number[] = this.game.getItemScreenLocation(i, j);
          const node: NodeInfo = this.game.getNodeInfo(i, j);

          const commonNodePaths = this.game.getCommonNodePaths(i, j)
          const innerColor = commonNodePaths.innerPath === PathId.noPath ? basicNodeColor :
            commonNodePaths.innerPath === PathId.path1 ? node1Color : node2Color;

          this.drawNode(canvas, pen, brush, nodeLoc, innerColor, node.innerNodeRadius, node.thickness, false);

        }
      }

      // draw cursors
      const cursorLocations: number[][] = this.game.getCursorScreenLocations();

      for (let i = 0; i < cursorLocations.length; i++) {
        pen.setColor(pathColors[i]);
        pen.setStrokeWidth(5);
        canvas.attachPen(pen);
        canvas.detachBrush();
        canvas.drawCircle(cursorLocations[i][0], cursorLocations[i][1], this.game.cursorRadius);
      }
    }
  }

  async createGame() {
    await this.game.create();
  }

  getGame(): Game {
    return this.game;
  }
}

export class CanvasController extends NodeController {
  private rootNode: FrameNode | null = null;
  private canvas = new Canvas();
  private mapCreated = false;

  makeNode(uiContext: UIContext): FrameNode {
    this.rootNode = new FrameNode(uiContext);
    if (this.rootNode === null) {
      return this.rootNode;
    }

    if (!this.mapCreated) {
      this.mapCreated = true;
      this.canvas.game.create().then(() => {
        this.invalidate();
      })
    }

    const renderNode = this.rootNode.getRenderNode();
    if (renderNode !== null) {
      this.canvas.frame = {
        x: 0,
        y: 0,
        width: 484,
        height: 484
      };
      this.canvas.pivot = { x: 0, y: 0 };
      this.canvas.scale = { x: 1, y: 1 };
      renderNode.appendChild(this.canvas);
      renderNode.clipToFrame = true;
    }
    return this.rootNode;
  }

  getGame(): Game {
    return this.canvas.getGame();
  }

  invalidate() {
    this.canvas.invalidate();
  }

  checkLevelCompleted(): boolean {
    return this.canvas.game.checkLevelComplete();
  }

  loadLevel(level: number) {
    this.canvas.loadLevel(level).then(() => {
      this.invalidate()
    });
  }
}