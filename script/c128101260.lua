--암군 테시난테 융합체
local s,id=GetID()
function s.initial_effect(c)
	-- 융합 소환 조건: "암군 테시난테"(128101254) + 어둠 속성 몬스터
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,128101254,aux.FilterBoolFunctionEx(Card.IsAttribute,ATTRIBUTE_DARK))

	--① 융합 소환 성공 시: 엑덱의 LV8/DARK/융합 1장 공개 → 그 몬스터의 '명시 소재' 1장을 덱에서 패로
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(function(e) return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION) end)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	--② 묘지로 보내졌을 경우: 필드의 카드 1장 파괴
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.destg)
	e2:SetOperation(s.desop)
	c:RegisterEffect(e2)
end
s.listed_series={0xc45}
s.listed_names={128101254} -- "암군 테시난테" (소재로 '카드명 지정' 인식용)

-------------------------------------------------------
-- ① 공개 + 서치
-------------------------------------------------------
local function isNamedFusion(fc)
	return fc:IsType(TYPE_FUSION) and fc:IsAttribute(ATTRIBUTE_DARK) and fc:IsLevel(8)
		and fc.material~=nil and #fc.material>0
end
local function deckMatFilter(c,code) return c:IsCode(code) and c:IsMonster() and c:IsAbleToHand() end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(function(fc)
			if not isNamedFusion(fc) then return false end
			for _,code in ipairs(fc.material) do
				if Duel.IsExistingMatchingCard(deckMatFilter,tp,LOCATION_DECK,0,1,nil,code) then
					return true
				end
			end
			return false
		end,tp,LOCATION_EXTRA,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(tp,function(fc)
		if not isNamedFusion(fc) then return false end
		for _,code in ipairs(fc.material) do
			if Duel.IsExistingMatchingCard(deckMatFilter,tp,LOCATION_DECK,0,1,nil,code) then
				return true
			end
		end
		return false
	end,tp,LOCATION_EXTRA,0,1,1,nil)
	local fc=g:GetFirst()
	if not fc then return end
	Duel.ConfirmCards(1-tp,fc)

	local codes={}
	for _,code in ipairs(fc.material) do
		if Duel.IsExistingMatchingCard(deckMatFilter,tp,LOCATION_DECK,0,1,nil,code) then
			table.insert(codes,code)
		end
	end
	if #codes==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CODE)
	local selcode=Duel.AnnounceNumber(tp,table.unpack(codes))
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local sg=Duel.SelectMatchingCard(tp,deckMatFilter,tp,LOCATION_DECK,0,1,1,nil,selcode)
	if #sg>0 then
		Duel.SendtoHand(sg,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,sg)
	end

	-- 디메리트: 이 턴, Extra에서 LIGHT/DARK만 특수 소환 가능
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetDescription(aux.Stringid(id,2)) -- 카드 텍스트: "이 턴, 자신은 빛/어둠 속성 몬스터밖에 엑스트라 덱에서 특수 소환할 수 없다."
	e1:SetTargetRange(1,0)
	e1:SetTarget(function(_e,sc)
		return sc:IsLocation(LOCATION_EXTRA)
			and not (sc:IsAttribute(ATTRIBUTE_LIGHT) or sc:IsAttribute(ATTRIBUTE_DARK))
	end)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

-------------------------------------------------------
-- ② 묘지 → 파괴
-------------------------------------------------------
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end
