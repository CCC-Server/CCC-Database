local s,id=GetID()
function s.initial_effect(c)
	-- ①: 패에서 이 카드를 공개 → 덱에서 몬스터 1장 장착
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.eqtg1)
	e1:SetOperation(s.eqop1)
	c:RegisterEffect(e1)

	-- ②: 엑스트라 덱 특수 소환 시 → 묘지에서 장착
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_EQUIP)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetRange(LOCATION_MZONE+LOCATION_HAND+LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1)
	e2:SetCondition(s.eqcon2)
	e2:SetTarget(s.eqtg2)
	e2:SetOperation(s.eqop2)
	c:RegisterEffect(e2)
end

-- 공통 필터: 네메시스 아티팩트 몬스터
function s.nemesis_monster(c)
	return c:IsSetCard(0x764) and c:IsType(TYPE_MONSTER)
end

-- -------------------------
-- ① 덱에서 장착
-- -------------------------

-- 장착 대상: 자신 필드의 앞면 몬스터
function s.eqtargetfilter(c)
	return c:IsFaceup()
end

function s.eqtg1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.nemesis_monster,tp,LOCATION_DECK,0,1,nil)
			and Duel.IsExistingMatchingCard(s.eqtargetfilter,tp,LOCATION_MZONE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g1=Duel.SelectMatchingCard(tp,s.eqtargetfilter,tp,LOCATION_MZONE,0,1,1,nil)
	e:SetLabelObject(g1:GetFirst())
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,nil,1,tp,LOCATION_DECK)
end

function s.eqop1(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.ConfirmCards(1-tp,c)
	if not c:IsRelateToEffect(e) then return end
	local tc=e:GetLabelObject()
	if not tc or not tc:IsFaceup() or not tc:IsControler(tp) then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g=Duel.SelectMatchingCard(tp,s.nemesis_monster,tp,LOCATION_DECK,0,1,1,nil)
	local ec=g:GetFirst()
	if not ec then return end

	if Duel.Equip(tp,ec,tc) then
		
		-- ★★ 장착 마법으로 변경(자괴 방지 핵심)
		local e0=Effect.CreateEffect(c)
		e0:SetType(EFFECT_TYPE_SINGLE)
		e0:SetCode(EFFECT_CHANGE_TYPE)
		e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e0:SetReset(RESET_EVENT+RESETS_STANDARD)
		e0:SetValue(TYPE_SPELL+TYPE_EQUIP)
		ec:RegisterEffect(e0)

		-- 장착 제한
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EQUIP_LIMIT)
		e1:SetProperty(EFFECT_FLAG_COPY_INHERIT+EFFECT_FLAG_OWNER_RELATE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		e1:SetValue(function(e,c) return e:GetOwner()==c end)
		ec:RegisterEffect(e1)

		-- 파괴 방지 (효과)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
		e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
		e2:SetRange(LOCATION_SZONE)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		e2:SetValue(1)
		ec:RegisterEffect(e2)
	end
end



-- -------------------------
-- ② 묘지에서 장착 (엑스트라 덱 특수 소환 트리거)
-- -------------------------

-- 트리거 조건: 엑스트라 덱에서 네메시스 아티팩트 몬스터 특수 소환
function s.eqcon2(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(function(c)
		return c:IsSetCard(0x764) and c:IsSummonPlayer(tp) and c:IsSummonLocation(LOCATION_EXTRA)
	end,1,nil)
end

function s.eqtg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.nemesis_monster,tp,LOCATION_GRAVE,0,1,nil)
			and Duel.IsExistingMatchingCard(s.nemesis_monster,tp,LOCATION_MZONE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g1=Duel.SelectMatchingCard(tp,s.nemesis_monster,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetTargetCard(g1)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g2=Duel.SelectMatchingCard(tp,s.nemesis_monster,tp,LOCATION_MZONE,0,1,1,nil)
	e:SetLabelObject(g2:GetFirst())
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,g1,1,0,0)
end

function s.eqop2(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	local ec=e:GetLabelObject()
	if not (tc and tc:IsRelateToEffect(e) and ec and ec:IsFaceup()) then return end

	if Duel.Equip(tp,tc,ec) then
		
		-- ★★ 장착 마법으로 변경(자괴 방지 핵심)
		local e0=Effect.CreateEffect(e:GetHandler())
		e0:SetType(EFFECT_TYPE_SINGLE)
		e0:SetCode(EFFECT_CHANGE_TYPE)
		e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
		e0:SetReset(RESET_EVENT+RESETS_STANDARD)
		e0:SetValue(TYPE_SPELL+TYPE_EQUIP)
		tc:RegisterEffect(e0)

		-- 장착 제한
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EQUIP_LIMIT)
		e1:SetProperty(EFFECT_FLAG_COPY_INHERIT+EFFECT_FLAG_OWNER_RELATE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		e1:SetValue(function(e,c) return e:GetOwner()==c end)
		tc:RegisterEffect(e1)

		-- 파괴 방지 (효과)
		local e2=Effect.CreateEffect(e:GetHandler())
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
		e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
		e2:SetRange(LOCATION_SZONE)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		e2:SetValue(1)
		tc:RegisterEffect(e2)
	end
end

