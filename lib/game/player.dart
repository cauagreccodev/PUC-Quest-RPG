import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'pirpg_game.dart';

enum PlayerState { idle, walk }

class Player extends SpriteAnimationGroupComponent<PlayerState> with HasGameReference<PIRPGGame> {
  late final SpriteAnimation _idleAnimation;
  late final SpriteAnimation _walkAnimation;
  
  Vector2 velocity = Vector2.zero();
  bool isMoving = false;
  bool isFlipped = false;

  Player({
    super.position,
    super.anchor = Anchor.center,
  }) : super(size: Vector2.all(64)); // Aumentado de 32 para 64

  @override
  Future<void> onLoad() async {
    await _loadAnimations();
    current = PlayerState.idle;
    return super.onLoad();
  }

  Future<void> _loadAnimations() async {
    // Assuming 6 frames for these soldier animations (standard for many asset packs)
    // If it's different, we can adjust later.
    debugPrint("Player: Loading animations...");
    final idleImage = await game.images.load('player/Soldier_Idle.png');
    final walkImage = await game.images.load('player/Soldier_Walk.png');
    debugPrint("Player: Animations loaded successfully.");
    
    _idleAnimation = SpriteAnimation.fromFrameData(
      idleImage,
      SpriteAnimationData.sequenced(
        amount: 6,
        stepTime: 0.1,
        textureSize: Vector2(idleImage.width / 6, idleImage.height.toDouble()),
      ),
    );

    _walkAnimation = SpriteAnimation.fromFrameData(
      walkImage,
      SpriteAnimationData.sequenced(
        amount: 6,
        stepTime: 0.1,
        textureSize: Vector2(walkImage.width / 6, walkImage.height.toDouble()),
      ),
    );

    animations = {
      PlayerState.idle: _idleAnimation,
      PlayerState.walk: _walkAnimation,
    };
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Update animation state based on movement
    if (velocity.length > 0) {
      current = PlayerState.walk;
      
      // Flip sprite based on direction
      if (velocity.x < 0 && !isFlipped) {
        flipHorizontallyAroundCenter();
        isFlipped = true;
      } else if (velocity.x > 0 && isFlipped) {
        flipHorizontallyAroundCenter();
        isFlipped = false;
      }
    } else {
      current = PlayerState.idle;
    }
  }
}
