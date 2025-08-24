--드래고니아-전격의 스테이츠
local s,id=GetID()
function s.initial_effect(c)
	-- Synchro Summon
Synchro.AddProcedure(c, aux.FilterBoolFunction(Card.IsSetCard, 0xc05), 1, 1, Synchro.NonTuner(Card.IsSetCard, 0xc05), 1, 99)
    c:EnableReviveLimit()
	-- ①: 사용하지 않은 메인 몬스터 존 지정 (1턴에 2번까지)
	local e1 = Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id, 0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(2, id)
	e1:SetOperation(s.zop)
	c:RegisterEffect(e1)

	-- ②: 지정한 존 수 × 200만큼 공격력 상승
	local e2 = Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)
end

-- ① 효과 처리: 메인 몬스터 존 1곳 지정 → 해당 존 비사용  
function s.zop(e, tp, eg, ep, ev, re, rp)
	local c = e:GetHandler()
	if not c:IsRelateToEffect(e) then return end

	-- 아직 사용되지 않은 메인 몬스터 존 중에서 1곳 선택
	local zone = Duel.SelectDisableField(tp, 1, LOCATION_MZONE, 0, 0)

	-- 선택된 존을 비사용 처리
	local dis = Effect.CreateEffect(c)
	dis:SetType(EFFECT_TYPE_FIELD)
	dis:SetCode(EFFECT_DISABLE_FIELD)
	dis:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	dis:SetTargetRange(1, 0)
	dis:SetValue(zone)
	-- 이 카드가 필드에 존재하는 동안 유지
	dis:SetReset(RESET_EVENT + RESETS_STANDARD)
	c:RegisterEffect(dis)

	-- 지정한 존의 개수를 플래그로 기록 (카드이동/턴 종료 시 초기화)
	c:RegisterFlagEffect(id, RESET_EVENT + RESETS_STANDARD + RESET_PHASE + PHASE_END, 0, 1)
end

-- ② 효과 처리: 플래그 개수 × 200 공격력 상승
function s.atkval(e, c)
	return c:GetFlagEffect(id) * 200
end
