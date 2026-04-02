import { common2D } from '@kit.ArkGraphics2D';
import HashMap from '@ohos.util.HashMap';
import resourceManager from '@ohos.resourceManager'
import GlobalContext from '../utils/GlobalContext';
import { ResourceUtils } from '../utils/ResourceUtils';

const wallColor: common2D.Color = {
  red: 255,
  green: 255,
  blue: 255,
  alpha: 100
};

export const basicNodeColor: common2D.Color = {
  red: 255,
  green: 255,
  blue: 255,
  alpha: 255
}

export const node1Color: common2D.Color = {
  red: 238,
  green: 205,
  blue: 94,
  alpha: 255
}

export const node2Color: common2D.Color = {
  red: 246,
  green: 89,
  blue: 147,
  alpha: 255
}

export enum ItemType {
  Wall,
  Node, // Basic Node
  Node1, // Green Node
  Node2, // Red Node
  CommonNode, // Two-pass node
  Empty
}

export interface NodeInfo {
  color: common2D.Color,
  color2?: common2D.Color,
  isEmpty: boolean,
  radius: number,
  thickness: number,
  innerNodeRadius: number
}

export enum PathId {
  noPath,
  path1,
  path2
}

export interface commonNodePathInfo {
  innerPath: PathId,
  outerPath: PathId
}

export enum MoveInfo {
  noMove,
  move,
  undoMove
}

export interface Map {
  grid: string,
  size: number[],
  cursors: number[][],
  nodes: number[][]
}

export class Game {
  readonly nodeRadius = 30;
  readonly wallNodeRadius = 10;
  readonly innerNodeRadius = 15;
  readonly cursorRadius = 40;
  readonly spaceBetweenNodes: number = 85;
  public map: Map = {
    grid: 'rect',
    size: [],
    cursors: [],
    nodes: []
  };
  public commonNodesColorInfo = new HashMap<string, commonNodePathInfo>()
  private canvasSizeX: number = 0;
  private canvasSizeY: number = 0;
  private nodesStartPosition: number[] = [0, 0];
  public path1: number[][] = []
  public path2: number[][] = []
  private draggingPaths: boolean[] = []
  private levelFileName: string = ''
  private playableSquareCount = 0;

  private async getLevelFromFile(fileName: string): Promise<Map> {
    const context = GlobalContext.getInstance().getAppContext();
    if (!context) {
      console.error('[LynkPuzzle] GlobalContext is undefined.')
      // empty map
      return {
        grid: 'rect',
        size: [],
        cursors: [],
        nodes: []
      };
    }
    return ResourceUtils.readRawfileJson<Map>(context, fileName);

  }

  public async create() {
    await this.getLevelFromFile(this.levelFileName).then((map) => {
      console.info(`[LynkPuzzle] cursors: ${map.cursors[0]}`)
      this.map = map;
      const paths = [this.path1, this.path2]

      for (let c = 0; c < this.map.cursors.length; c++) {
        paths[c].push(this.map.cursors[c])
        this.draggingPaths.push(false)
      }

      for (let j = 0; j < this.map.nodes.length; j++) {
        for (let i = 0; i < this.map.nodes[j].length; i++) {
          if (this.map.nodes[j][i] === ItemType.CommonNode) {
            this.playableSquareCount++;
            console.info(`[LynkPuzzle] commonNode at (${i}, ${j})`)
            this.commonNodesColorInfo.set(`${i},${j}`, { innerPath: PathId.noPath, outerPath: PathId.noPath })
          }
          if (this.map.nodes[j][i] !== ItemType.Wall && this.map.nodes[j][i] !== ItemType.Empty) {
            this.playableSquareCount++;
          }
        }
      }

      const nodeMapSizeX = this.map.size[0] * this.spaceBetweenNodes
      const nodeMapSizeY = this.map.size[1] * this.spaceBetweenNodes

      const rectangularOffset = this.map.grid === 'hex' ? 0 : 1.5 * this.nodeRadius;
      const startPositionX = (this.canvasSizeX - nodeMapSizeX) / 2 + rectangularOffset
      const startPositionY = (this.canvasSizeY - nodeMapSizeY) / 2 + 1.5 * this.nodeRadius
      this.nodesStartPosition = [startPositionX, startPositionY]
    });
  }

  constructor(levelFileName: string, canvasSizeX: number, canvasSizeY: number) {
    this.canvasSizeX = canvasSizeX;
    this.canvasSizeY = canvasSizeY;
    this.levelFileName = levelFileName
  }

  getItemScreenLocation(x: number, y: number): number[] {
    // offset for hexagonal offset
    const offset = this.map.grid === 'hex' && y % 2 === 0 ? 0.5 : 0;

    const screenLocation =
      [this.nodesStartPosition[0] + (x + offset) * this.spaceBetweenNodes,
        this.nodesStartPosition[1] + y * this.spaceBetweenNodes]
    return screenLocation;
  }

  getCursorScreenLocations() {
    const cursorLocations: number[][] = []
    for (let i = 0; i < this.map.cursors.length; i++) {
      // offset for hexagonal offset
      const offset = this.map.grid === 'hex' && this.map.cursors[i][1] % 2 === 0 ? 0.5 : 0;
      const cursorLocation =
        [this.nodesStartPosition[0] + (this.map.cursors[i][0] + offset) * this.spaceBetweenNodes,
          this.nodesStartPosition[1] + this.map.cursors[i][1] * this.spaceBetweenNodes]
      cursorLocations.push(cursorLocation);
    }
    return cursorLocations;
  }

  getNodeInfo(x: number, y: number): NodeInfo {

    let nodeRadius = this.nodeRadius;
    const thickness = 6;
    let nodeColor: common2D.Color = wallColor;
    let innerNodeRadius = 0

    if (this.map.nodes[y][x] === ItemType.Node || this.map.nodes[y][x] === ItemType.CommonNode) { // basic node
      nodeColor = basicNodeColor;
    } else if (this.map.nodes[y][x] === ItemType.Node1) {
      nodeColor = node1Color
    } else if (this.map.nodes[y][x] === ItemType.Node2) {
      nodeColor = node2Color
    }

    let isEmpty = true;
    for (let i = 0; i < this.path1.length; i++) {
      if (this.path1[i][0] === x && this.path1[i][1] === y) {
        isEmpty = false;
        nodeColor = node1Color;
        break;
      }
    }

    for (let i = 0; i < this.path2.length; i++) {
      if (this.path2[i][0] === x && this.path2[i][1] === y) {
        isEmpty = false;
        nodeColor = node2Color;
        break;
      }
    }

    if (this.map.nodes[y][x] === ItemType.Wall) {
      nodeRadius = this.wallNodeRadius;
      isEmpty = false;
    } else if (this.map.nodes[y][x] === ItemType.Empty) {
      nodeRadius = 0;
      isEmpty = false;
    }

    if (this.map.nodes[y][x] === ItemType.CommonNode) {
      innerNodeRadius = this.innerNodeRadius;
    }

    const info: NodeInfo = {
      color: nodeColor,
      isEmpty: isEmpty,
      radius: nodeRadius,
      thickness: thickness,
      innerNodeRadius: innerNodeRadius
    }
    return info;
  }

  public startDragging(x: number, y: number): boolean {
    const mouseCoords = this.screenLocationToCoords(x, y);
    for (let i = 0; i < this.map.cursors.length; i++) {
      if (mouseCoords[0] === this.map.cursors[i][0] && mouseCoords[1] === this.map.cursors[i][1]) {
        for (let d = 0; d < this.draggingPaths.length; d++) {
          if (d === i) {
            this.draggingPaths[d] = true
          } else {
            this.draggingPaths[d] = false
          }
        }
        return true;
      }
    }
    for (let d = 0; d < this.draggingPaths.length; d++) {
      this.draggingPaths[d] = false
    }
    return false;
  }

  private screenLocationToCoords(xScreen: number, yScreen: number) {

    const y = Math.floor((yScreen - this.nodesStartPosition[1] + this.spaceBetweenNodes / 2) / this.spaceBetweenNodes)
    const offset = this.map.grid === 'hex' && y % 2 === 0 ? 0.5 * this.spaceBetweenNodes : 0;
    const x =
      Math.floor((xScreen - offset - this.nodesStartPosition[0] + this.spaceBetweenNodes / 2) / this.spaceBetweenNodes)
    console.info(`[LynkPuzzle] screenLocationToCoords: (${xScreen}, ${yScreen}) to (${x}, ${y})`);
    return [x, y];
  }

  public move(xScreen: number, yScreen: number): MoveInfo {
    let moveInfo = MoveInfo.noMove
    const coords = this.screenLocationToCoords(xScreen, yScreen);
    const x = coords[0]
    const y = coords[1]
    console.info(`[LynkPuzzle] moving to (${x}, ${y})`)

    let cursorLoc: number[] = this.map.cursors[0]
    let path: number[][] = this.path1
    let nodeType = ItemType.Node1
    let pathId: PathId = PathId.path1

    if (this.draggingPaths.length > 1 && this.draggingPaths[1]) {
      cursorLoc = this.map.cursors[1]
      path = this.path2
      pathId = PathId.path2
      nodeType = ItemType.Node2
    }

    const undoMove = path.length >= 2 && path[path.length - 2][0] === x && path[path.length - 2][1] === y
    if (this.isInArea(x, y) &&
    this.isNeighbour([x, y], cursorLoc) &&
      (this.notPassed(x, y, path) || undoMove) &&
    this.checkNodeColor(x, y, nodeType) &&
      this.map.nodes[y][x] !== ItemType.Wall &&
      this.map.nodes[y][x] !== ItemType.Empty) {
      // if it is an undo move
      if (undoMove) {
        moveInfo = MoveInfo.undoMove
        const poppedPosition = path.pop();
        // update common nodes paths
        if (poppedPosition) {
          const key = `${poppedPosition[0]},${poppedPosition[1]}`
          if (this.commonNodesColorInfo.hasKey(key)) {
            const commonNodePaths = this.commonNodesColorInfo.get(key)
            if (commonNodePaths.outerPath === pathId) {
              this.commonNodesColorInfo.set(key, { innerPath: commonNodePaths.innerPath, outerPath: PathId.noPath })
            } else if (commonNodePaths.innerPath === pathId) {
              this.commonNodesColorInfo.set(key, { innerPath: PathId.noPath, outerPath: commonNodePaths.outerPath })
            } else {
              console.error('[LynkPuzzle] Never should enter here.')
            }
          }
        }
      } else {
        moveInfo = MoveInfo.move
        path.push([x, y]);
        // update common nodes paths
        const key = `${x},${y}`;
        if (this.commonNodesColorInfo.hasKey(key)) {
          const commonNodePaths = this.commonNodesColorInfo.get(key)
          if (commonNodePaths.innerPath === PathId.noPath) {
            this.commonNodesColorInfo.set(key, { innerPath: pathId, outerPath: commonNodePaths.outerPath })
          } else if (commonNodePaths.outerPath === PathId.noPath) {
            this.commonNodesColorInfo.set(key, { innerPath: commonNodePaths.innerPath, outerPath: pathId })
          }
        }
      }

      for (let d = 0; d < this.draggingPaths.length; d++) {
        if (this.draggingPaths[d]) {
          this.map.cursors[d] = [x, y]
          break
        }
      }

      console.info(`[LynkPuzzle] cursor is moved to (${x}, ${y})`)
    }
    return moveInfo
  }

  // if node is a color specific, path color and node color are same, returns true
  private checkNodeColor(x: number, y: number, nodeType: ItemType): boolean {
    if (this.map.nodes[y][x] === ItemType.Node || this.map.nodes[y][x] === ItemType.CommonNode ||
      this.map.nodes[y][x] === nodeType) {
      return true;
    }
    return false;
  }

  private isNeighbour(loc1: number[], loc2: number[]) {
    // if loc1 equals loc2, these nodes are not neighbours
    const dx = loc1[0] - loc2[0];
    const dy = loc1[1] - loc2[1];

    if (this.map.grid === 'hex') {
      // same row neighbours
      if (dy === 0 && Math.abs(dx) === 1) {
        return true;
      }

      // vertical neighbours
      if (Math.abs(dy) === 1) {
        if (loc2[1] % 2 === 1) {
          return dx === 0 || dx === -1;
        } else {
          return dx === 0 || dx === 1;
        }
      }

      return false;
    } else {
      if (Math.abs(dx) + Math.abs(dy) === 1) {
        console.info(`[LynkPuzzle] Neighbour`)
        return true;
      }
    }

    return false;
  }

  private isInArea(x: number, y: number) {
    if (0 <= x && x < this.map.size[0] && 0 <= y && y < this.map.size[1]) {
      console.info(`[LynkPuzzle] InArea`)
      return true;
    }
    return false;
  }

  private notPassed(x: number, y: number, selfPath: number[][]): boolean {
    const paths = [this.path1, this.path2]
    for (const path of paths) {
      const pathLength = path.length;

      for (let i = 0; i < pathLength; i++) {

        if (this.map.nodes[y][x] === ItemType.CommonNode) {
          const commonNodePaths = this.getCommonNodePaths(x, y)
          if (commonNodePaths.innerPath !== PathId.noPath && commonNodePaths.outerPath !== PathId.noPath) {
            return false;
          }
        } else if (path[i][0] === x && path[i][1] === y) {
          return false;
        }
      }
    }

    return true;
  }

  public getCommonNodePaths(x: number, y: number) {
    console.info(`[LynkPuzzle] commonNodeInfo exist (${x}, ${y}): ${this.commonNodesColorInfo.hasKey(`${x},${y}`)}`)
    return this.commonNodesColorInfo.get(`${x},${y}`)
  }

  public checkLevelComplete(): boolean {
    let pathsTotalLen = 0;
    const paths = [this.path1, this.path2]
    for (const p of paths) {
      pathsTotalLen += p.length
    }

    const remainingSquare = this.playableSquareCount - pathsTotalLen;
    console.info(`[LynkPuzzle] remaining square: ${remainingSquare}`)
    if (remainingSquare === 0) { // completed
      return true;
    }
    return false;
  }
}