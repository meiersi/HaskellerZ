{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE RecordWildCards #-}

module Player where

import Control.Arrow
import Control.Lens
import Data.AffineSpace
import Data.Default
import Data.VectorSpace
import Graphics.Gloss
import Graphics.Gloss.Data.Vector
import Graphics.Gloss.Geometry.Angle

import Keys

playerR :: Float
playerR = 30

data Player
  = Player
    { _pPos :: !Point
    , _pSpd :: !(Float, Float)
    , _pAng :: !Float
    , _pRot :: !Float
    , _pColor :: !Color
    , _pFire :: !Bool
    , _pName :: !String
    , _pScore :: !Float
    } deriving (Show)
makeLenses ''Player

instance Default Player where
  def = Player (0,0) (0,0) 0 0 black False "" 0

drawPlayer :: Player -> Picture
drawPlayer Player{..} = translateP _pPos $ rotate (-radToDeg _pAng) $
                        Pictures [ body1, body2, flame ]
  where
    body1 = color (dim $ dim _pColor) $ circleSolid playerR
    body2 = color (light _pColor) $ polygon [(60,0),(-42,-12),(-32,0),(-42,12)]
    flamePath = [(-50,0), (-60,6), (-70,8), (-80,6), (-90,0)]
    flamePath' = tail $ reverse $ tail $ map (second negate) flamePath
    flame = if not _pFire then Blank
            else color red $ polygon $ flamePath ++ flamePath'

translateP :: Point -> Picture -> Picture
translateP (x,y) = translate x y


stepPlayer :: Float -> Player -> Player
stepPlayer dt p@Player{..} = p & pPos .~ pos' & pSpd .~ spd' & pAng +~ 3*dt*_pRot
  where
    pos' = _pPos .+^ dt *^ _pSpd
    spd' = _pSpd ^+^ dt *^ acc
    acc = -0.2 *^ _pSpd ^+^ if _pFire then 72 *^ dir else (0,0)
    dir = unitVectorAtAngle _pAng

updatePlayerByKeys :: ActiveKeys -> Player -> Player
updatePlayerByKeys (ActiveKeys l r d) = pRot .~ rot >>> pFire .~ not d
  where
    rot = case (l,r) of
      (True, False) -> 1
      (False, True) -> -1
      _ -> 0

bounceOffBorder :: (Float,Float) -> Player -> Player
bounceOffBorder arenaSize p@Player{..} = p & horiz & vert
  where
    (w,h) = arenaSize & both %~ (/2) & both -~ playerR
    (x,y) = _pPos
    (vx, vy) = _pSpd
    horiz = if abs x > w && signum x == signum vx then pSpd._1 %~ negate else id
    vert  = if abs y > h && signum y == signum vy then pSpd._2 %~ negate else id

drawScore :: (Float,Float) -> Int -> Player -> Picture
drawScore sz k Player{..} = translate x y $ color c $ Pictures [ name, score ]
  where
    (w,h) = sz & both %~ (/2)
    x = w - 150
    y = h - 50 - 30 * fromIntegral k
    c = dark $ dim _pColor
    sc = scale 0.18 0.18
    name = sc $ Text _pName
    score = translate 80 0 $ sc $ Text (show $ (floor _pScore :: Int))
