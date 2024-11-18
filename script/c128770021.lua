local s,id=GetID()
function s.initial_effect(c)
	 -- Synchro Summon
	Synchro.AddProcedure(c, aux.FilterBoolFunction(Card.IsType, TYPE_TUNER), 1, 1, Synchro.NonTuner(Card.IsSetCard, 0x30d), 1, 99)
	c:EnableReviveLimit()
	-- Effect 1: Draw 1 card when Synchro Summoned
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetCategory(CATEGORY_DRAW)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCondition(s.drcon)
	e1:SetTarget(s.drtg)
	e1:SetOperation(s.drop)
	c:RegisterEffect(e1)

	-- Effect 2: Special Summon "M.A-꼬마 마녀의 친구 토큰"
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_TOKEN)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_BATTLE_DESTROYING)
	e2:SetCondition(s.tkcon)
	e2:SetTarget(s.tktg)
	e2:SetOperation(s.tkop)
	c:RegisterEffect(e2)
end

-- Effect 1: Condition and operation to draw 1 card
function s.drcon(e, tp, eg, ep, ev, re, r, rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end
function s.drtg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk==0 then return Duel.IsPlayerCanDraw(tp, 1) end
	Duel.SetOperationInfo(0, CATEGORY_DRAW, nil, 0, tp, 1)
end
function s.drop(e, tp, eg, ep, ev, re, r, rp)
	Duel.Draw(tp, 1, REASON_EFFECT)
end

-- Effect 2: Condition and operation to Special Summon a token
function s.tkcon(e, tp, eg, ep, ev, re, r, rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	return bc and bc:IsLocation(LOCATION_GRAVE) and bc:IsType(TYPE_MONSTER)
end
function s.tktg(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk==0 then return Duel.GetLocationCount(tp, LOCATION_MZONE)>0
		and Duel.IsPlayerCanSpecialSummonMonster(tp, 128770022, 0, TYPES_TOKEN, 0, 0, 5, RACE_FIEND, ATTRIBUTE_DARK) end
	Duel.SetOperationInfo(0, CATEGORY_SPECIAL_SUMMON, nil, 1, 0, 0)
	Duel.SetOperationInfo(0, CATEGORY_TOKEN, nil, 1, 0, 0)
end
function s.tkop(e, tp, eg, ep, ev, re, r, rp)
	if Duel.GetLocationCount(tp, LOCATION_MZONE)<=0 then return end
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	if not bc then return end
	local atk=bc:GetBaseAttack()

	-- 토큰을 생성하고 특수 소환
	local token=Duel.CreateToken(tp, 128770022) -- 토큰 ID를 사용
	if token and Duel.SpecialSummon(token, 0, tp, tp, false, false, POS_FACEUP)~=0 then
		-- 토큰이 성공적으로 특수 소환된 경우에만 공격력과 수비력을 설정
		local e1=Effect.CreateEffect(token)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_ATTACK)
		e1:SetValue(atk)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		token:RegisterEffect(e1)

		local e2=Effect.CreateEffect(token)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_SET_DEFENSE)
		e2:SetValue(0)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		token:RegisterEffect(e2)
	end
end
