local s,id=GetID()
s.listed_names={CARD_FLAME_SWORDSMAN}

function s.initial_effect(c)
	-- ① 발동 시: 덱에서 "화염의 검사" 관련 몬스터 1장 서치 (선택)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- ② 장착 효과
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_EQUIP)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_FZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.eqtg)
	e2:SetOperation(s.eqop)
	c:RegisterEffect(e2)

	-- ③ 융합 특수 소환
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,2))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetRange(LOCATION_FZONE)
	e3:SetCountLimit(1,{id,2})
	e3:SetCondition(s.spcon)
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)
end

-- ① 효과: 덱 서치
function s.thfilter(c)
	return c:IsMonster() and c:ListsCode(CARD_FLAME_SWORDSMAN) and c:IsAbleToHand()
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil)
		and Duel.SelectYesNo(tp,aux.Stringid(id,3)) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
		if #g>0 then
			Duel.SendtoHand(g,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,g)
		end
	end
end

-- ② 장착 효과
function s.eqtgfilter(c)
	return c:IsFaceup()
end
function s.eqgfilter(c)
	return c:IsMonster() and c:ListsCode(CARD_FLAME_SWORDSMAN) and not c:IsForbidden()
end
function s.eqtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.eqtgfilter(chkc) end
	if chk==0 then
		return Duel.IsExistingTarget(s.eqtgfilter,tp,LOCATION_MZONE,0,1,nil)
			and Duel.IsExistingMatchingCard(s.eqgfilter,tp,LOCATION_GRAVE,0,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,s.eqtgfilter,tp,LOCATION_MZONE,0,1,1,nil)
end

function s.equip_limit(e,c)
	return c==e:GetLabelObject()
end

function s.eqop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if not tc:IsRelateToEffect(e) or not tc:IsFaceup() then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local g=Duel.SelectMatchingCard(tp,s.eqgfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	local ec=g:GetFirst()
	if ec and Duel.Equip(tp,ec,tc) then
		-- 장착 제한
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_EQUIP_LIMIT)
		e1:SetProperty(EFFECT_FLAG_COPY_INHERIT)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		e1:SetValue(s.equip_limit)
		e1:SetLabelObject(tc)
		ec:RegisterEffect(e1)
	end
end

-- ③ 융합 특수 소환 (수정된 조건 포함)
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	-- 상대 특수 소환 + 내가 장착카드를 장착한 융합 몬스터를 제어 중
	return eg:IsExists(Card.IsSummonPlayer,1,nil,1-tp)
		and Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_SZONE,0,1,nil)
end

function s.spfilter1(c)
	-- 수정됨: TYPE_MONSTER 제거, 장착 대상이 융합 몬스터인지만 확인
	return c:IsType(TYPE_EQUIP)
		and c:GetEquipTarget() and c:GetEquipTarget():IsType(TYPE_FUSION)
end

function s.spfilter2(c,e,tp)
	return (c:IsCode(CARD_FLAME_SWORDSMAN) or c:ListsCode(CARD_FLAME_SWORDSMAN))
		and c:IsType(TYPE_FUSION)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.spfilter1,tp,LOCATION_SZONE,0,1,nil)
			and Duel.IsExistingMatchingCard(s.spfilter2,tp,LOCATION_EXTRA,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.spfilter1,tp,LOCATION_SZONE,0,1,1,nil)
	local gc=g:GetFirst()
	if not gc then return end
	local mc=gc:GetEquipTarget()
	if Duel.SendtoGrave(Group.FromCards(gc,mc),REASON_EFFECT)==2 then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sg=Duel.SelectMatchingCard(tp,s.spfilter2,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
		if #sg>0 then
			Duel.SpecialSummon(sg,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
			sg:GetFirst():CompleteProcedure()
		end
	end
end
