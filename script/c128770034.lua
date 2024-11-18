-- M.A 링크 몬스터 스크립트 (링크 1)
-- 카드의 기본 설정
local s, id = GetID()
function s.initial_effect(c)
	-- 링크 소환
	Link.AddProcedure(c, aux.FilterBoolFunction(Card.IsSetCard, 0x30d), 1, 1, s.lcheck)
	c:EnableReviveLimit()
	
	-- 효과 1: 대상 내성
	local e1 = Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(aux.tgoval)
	c:RegisterEffect(e1)
	
	-- 효과 2: 공격력 0으로 만들기
	local e2 = Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id, 0))
	e2:SetCategory(CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_FIELD + EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_ATTACK_ANNOUNCE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCondition(s.atkcon)
	e2:SetCost(s.atkcost)
	e2:SetOperation(s.atkop)
	c:RegisterEffect(e2)
end

-- 링크 소환 체크: 레벨 4 이하의 "M.A" 몬스터
function s.lcheck(g, lc)
	return g:IsExists(Card.IsLevelBelow, 1, nil, 4)
end

-- 공격 선언 시 조건
function s.atkcon(e, tp, eg, ep, ev, re, r, rp)
	local at = Duel.GetAttacker()
	return at:IsControler(1 - tp)
end

-- 코스트: 이 카드를 릴리스
function s.atkcost(e, tp, eg, ep, ev, re, r, rp, chk)
	if chk == 0 then return e:GetHandler():IsReleasable() end
	Duel.Release(e:GetHandler(), REASON_COST)
end

-- 효과 처리: 상대 몬스터의 공격력을 0으로 변경
function s.atkop(e, tp, eg, ep, ev, re, r, rp)
	local at = Duel.GetAttacker()
	if at and at:IsFaceup() and at:IsRelateToBattle() then
		local e1 = Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_SET_ATTACK_FINAL)
		e1:SetValue(0)
		e1:SetReset(RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END)
		at:RegisterEffect(e1)
	end
end
